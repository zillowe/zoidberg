local version = ZOI.VERSION or "0.9.6"
-- Upstream publishes no release tarball or signature, so the GitHub archive
-- of the release tag is used. This hash matches Gentoo's Manifest and Arch
-- Linux's sha512sums for the same archive.
local sha512 = "77bc255688606cbc3a9d40cc1d417ebf748d04b8d837d793708b58431857ebfaa077f00cebfcf03c58ce56985feb63f9f8eb70cce21ba304ca3418a0fe1b61d1"

metadata({
	name = "libcap-ng",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "A library for Linux that makes using posix capabilities easy",
	website = "https://people.redhat.com/sgrubb/libcap-ng/",
	license = "GPL-2.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Steve Grubb",
		website = "https://people.redhat.com/sgrubb/libcap-ng/",
	},
	bins = { "captest", "filecap", "netcap", "pscap" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "python" },
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libtool",
					"pacman:make",
					"pacman:python",
					"pacman:swig",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/glibc",
				},
			},
			-- Python bindings (capng), split like Arch Linux's python-capng.
			python = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/libcap-ng",
					"zoi:@core/python",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/stevegrubb/libcap-ng/archive/refs/tags/v$VER.tar.gz" \
			-o "libcap-ng-$VER.tar.gz"
		echo "$SHA512  libcap-ng-$VER.tar.gz" | sha512sum -c -
		tar -xf "libcap-ng-$VER.tar.gz"
		cd "libcap-ng-$VER"
		# The tag archive ships no configure script; NEWS is required by automake
		touch NEWS
		autoreconf -fiv
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "libcap-ng-$VER"
		./configure \
			--enable-static=no \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-python3 \
			--without-python
		make -j"$(nproc)"
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			make -C "libcap-ng-$VER" DESTDIR="$ROOT" install
			# The Python bindings go to the python subpackage
			rm -rf "$ROOT"/usr/lib/python3*
		]],
			opts
		)
	elseif sub == "python" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/lib
			# Install into a scratch root and keep only the Python bindings.
			TMP_DIR="$(mktemp -d)"
			make -C "libcap-ng-$VER" DESTDIR="$TMP_DIR" install
			cp -a "$TMP_DIR"/usr/lib/python3* "$ROOT"/usr/lib/
			rm -rf "$TMP_DIR"
		]],
			opts
		)
	end

	zlicense("libcap-ng-" .. version .. "/COPYING")
	zlicense("libcap-ng-" .. version .. "/COPYING.LIB")
end

function test()
	cmd([[
		test -e /usr/lib/libcap-ng.so.0 || true
	]])
end

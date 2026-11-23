-- NOTE: libtool must be rebuilt (revision bump) with each new GCC version.
local version = ZOI.VERSION or "2.6.2"
local sha512 = "7517648aaa704a87a35ce23c47dd6415c1ac81056aadb076960cd93c0ee31c431ab95aa85a4cc1eaaee1dcf860a90898fb6514f0bb4aa70b940757c8301260cf"
-- Release signing key (Ileana Dumitrescu), from upstream's keyring.
local signing_key = "FA26CA784BE188927F22B99F6570EA01146F7354"

metadata({
	name = "libtool",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "A generic library support script",
	website = "https://www.gnu.org/software/libtool",
	license = "GPL-2.0-or-later WITH Libtool-exception AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "libtool", "libtoolize" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
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
					"pacman:gcc",
					"pacman:m4",
					"pacman:make",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/tar",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libtool-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/libtool" \
				"https://mirrors.kernel.org/gnu/libtool" \
				"https://ftp.gnu.org/gnu/libtool"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libtool-$VER.tar.xz"
		fetch "libtool-$VER.tar.xz.sig"
		echo "$SHA512  libtool-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libtool-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "libtool-$VER"
		./configure \
			--prefix=/usr \
			lt_cv_sys_lib_dlsearch_path_spec="/usr/lib /usr/lib32"
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "libtool-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("libtool-" .. version .. "/COPYING")
	-- libltdl is LGPL-2.1-or-later.
	zlicense("libtool-" .. version .. "/libltdl/COPYING.LIB")
end

function test()
	cmd([[
		/usr/bin/libtool --version || libtool --version
	]])
end

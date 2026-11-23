local version = ZOI.VERSION or "1.1.1"
local sha512 = "47b7e1c187c9d1ec52777ba08d636a8178f811816b7d5eae28ef7680e2d4516428445572e655a2b60e8f3af1c6788268cfa16532e4a2ba761f8ba55bb3969870"
-- Release signing key (Netfilter Core Team), matches Arch's validpgpkeys.
local signing_key = "8C5F7146A1757A65E2422A94D70D1A666ACF2B21"

metadata({
	name = "libnetfilter_conntrack",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Library providing an API to the in-kernel connection tracking state table",
	website = "https://www.netfilter.org/projects/libnetfilter_conntrack/",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Netfilter Project",
		website = "https://www.netfilter.org",
	},
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
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libmnl",
					"pacman:libnfnetlink",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libmnl",
			"zoi:@core/libnfnetlink",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libnetfilter_conntrack-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.netfilter.org/projects/libnetfilter_conntrack/files"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libnetfilter_conntrack-$VER.tar.xz"
		fetch "libnetfilter_conntrack-$VER.tar.xz.sig"
		echo "$SHA512  libnetfilter_conntrack-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libnetfilter_conntrack-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "libnetfilter_conntrack-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "libnetfilter_conntrack-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("libnetfilter_conntrack-" .. version .. "/COPYING")
end

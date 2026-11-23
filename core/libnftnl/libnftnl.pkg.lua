local version = ZOI.VERSION or "1.3.2"
local sha512 = "ee60231f25c51ce45a8117e5a255265964ed024184c6b5ff4a883e6bbab6b0a66a73b6ca31be1c7055d778c5e7d780f483437eb9d27028dd9fcb6cc69af676ca"
-- Release signing key (Netfilter Core Team), matches Arch's validpgpkeys.
local signing_key = "8C5F7146A1757A65E2422A94D70D1A666ACF2B21"

metadata({
	name = "libnftnl",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Netfilter library providing interface to the nf_tables subsystem",
	website = "https://www.netfilter.org/projects/libnftnl/",
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
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libnftnl-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.netfilter.org/projects/libnftnl/files"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libnftnl-$VER.tar.xz"
		fetch "libnftnl-$VER.tar.xz.sig"
		echo "$SHA512  libnftnl-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libnftnl-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "libnftnl-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "libnftnl-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("libnftnl-" .. version .. "/COPYING")
end

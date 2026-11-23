local version = ZOI.VERSION or "1.0.5"
local sha512 = "16fa48e74c9da7724a85c655dfb0abd8369392627934639d65de951543e1447ac3e048d231248f1ce8861443c2ef62654a85a81feeedbbffaf2e5744f6cf4c9f"
-- Release signing key (Netfilter Core Team), from upstream's published keys.
local signing_key = "37D964ACC04981C75500FB9BD55D978A8A1420E4"

metadata({
	name = "libmnl",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Minimalistic user-space library oriented to Netlink developers",
	website = "https://www.netfilter.org/projects/libmnl/",
	license = "LGPL-2.1-or-later",
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
					"pacman:make",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libmnl-" .. version .. ".tar.bz2"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.netfilter.org/projects/libmnl/files"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libmnl-$VER.tar.bz2"
		fetch "libmnl-$VER.tar.bz2.sig"
		echo "$SHA512  libmnl-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libmnl-$VER.tar.bz2"]], opts)
end

function build()
	cmd(
		[[
		cd "libmnl-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libmnl-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("libmnl-" .. version .. "/COPYING")
end

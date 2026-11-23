local version = ZOI.VERSION or "1.0.2"
local sha512 = "a5e9ae22831f1d17703f83953f3b0ef898e8b3fa7f0f771b038db51816ddae3158574380ac4d45c09fb8fbb8677e2ccdcc5c4736e3b09de06eac99f899130854"
-- Release signing key (Netfilter Core Team, the older key that signed 1.0.2;
-- it expired in 2024 but the signature predates that), matches Arch's
-- validpgpkeys and core/libmnl.
local signing_key = "37D964ACC04981C75500FB9BD55D978A8A1420E4"

metadata({
	name = "libnfnetlink",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Low-level library for netfilter related kernel/userspace communication",
	website = "https://www.netfilter.org/projects/libnfnetlink/",
	license = "GPL-2.0-only",
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
					"pacman:bzip2",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:tar",
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
	local tarball = "libnfnetlink-" .. version .. ".tar.bz2"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.netfilter.org/projects/libnfnetlink/files"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libnfnetlink-$VER.tar.bz2"
		fetch "libnfnetlink-$VER.tar.bz2.sig"
		echo "$SHA512  libnfnetlink-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libnfnetlink-$VER.tar.bz2"]], opts)
end

function build()
	cmd(
		[[
		cd "libnfnetlink-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "libnfnetlink-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("libnfnetlink-" .. version .. "/COPYING")
end

local version = ZOI.VERSION or "1.8.13"
local sha512 = "3aefd76ca60d00f46ba4d6f39cbcfdc60517d03b6714da25dcd67542f6f4eea8d82c4855bdd9124efe18b769f41951772b8340a6eda75b85f8dd52b2289b145b"
-- Release signing key (Netfilter Core Team), from upstream's published keys.
local signing_key = "8C5F7146A1757A65E2422A94D70D1A666ACF2B21"

metadata({
	name = "iptables",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Linux kernel packet control tool (legacy backend) and the libxtables library",
	website = "https://www.netfilter.org/projects/iptables/",
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
					"pacman:linux-api-headers",
					"pacman:make",
					"pacman:pkgconf",
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

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	local tarball = "iptables-" .. version .. ".tar.xz"
	sh([[
		fetch() {
			for base in \
				"https://www.netfilter.org/projects/iptables/files"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "iptables-$VER.tar.xz"
		fetch "iptables-$VER.tar.xz.sig"
		echo "$SHA512  iptables-$VER.tar.xz" | sha512sum -c -
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "iptables-$VER.tar.xz"]])
end

function build()
	sh([[
		cd "iptables-$VER"
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--sysconfdir=/etc \
			--libexecdir=/usr/lib \
			--disable-static \
			--disable-nftables \
			--disable-connlabel \
			--enable-shared \
			--enable-devel
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "iptables-$VER"
		make DESTDIR="$ROOT" install
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/iptables/$(basename "$f")"
		done
		true
	]])
end

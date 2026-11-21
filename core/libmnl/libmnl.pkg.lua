local version = ZOI.VERSION or "1.0.5"
local sha512 = "16fa48e74c9da7724a85c655dfb0abd8369392627934639d65de951543e1447ac3e048d231248f1ce8861443c2ef62654a85a81feeedbbffaf2e5744f6cf4c9f"
-- Release signing key (Netfilter Core Team), from upstream's published keys.
local signing_key = "37D964ACC04981C75500FB9BD55D978A8A1420E4"

metadata({
	name = "libmnl",
	repo = "core",
	version = version,
	revision = "1",
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
	local tarball = "libmnl-" .. version .. ".tar.bz2"
	sh([[
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
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "libmnl-$VER.tar.bz2"]])
end

function build()
	sh([[
		cd "libmnl-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libmnl-$VER"
		make DESTDIR="$ROOT" install
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libmnl/$(basename "$f")"
		done
		true
	]])
end

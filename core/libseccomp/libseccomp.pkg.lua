local version = ZOI.VERSION or "2.6.0"
local sha512 = "9039478656d9b670af2ff4cb67b6b1fa315821e59d2f82ba6247e988859ddc7e3d15fea159eccca161bf2890828bb62aa6ab4d6b7ff55f27a9d6bd9532eeee1b"
-- Upstream signs releases (key 7100AADFAE6E6E940D2E0AD655E45A5AE8CA7C8A, Paul Moore),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "libseccomp",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Enhanced seccomp library",
	website = "https://github.com/seccomp/libseccomp",
	license = "LGPL-2.1-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Paul Moore",
		website = "https://github.com/seccomp/libseccomp",
	},
	bins = { "scmp_sys_resolver" },
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
					"pacman:gperf",
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
	local tarball = "libseccomp-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://github.com/seccomp/libseccomp/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libseccomp-$VER.tar.gz"
		echo "$SHA512  libseccomp-$VER.tar.gz" | sha512sum -c -
	]])
	sh([[tar -xf "libseccomp-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "libseccomp-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libseccomp-$VER"
		make DESTDIR="$ROOT" install
		for f in LICENSE; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libseccomp/$(basename "$f")"
		done
		true
	]])
end

local version = ZOI.VERSION or "1.19"
local sha512 = "5d1b6a15337e4cd5991817c1957f97fc4ed98659870017c08f26f754e34add31d639d55ee77ca31f29bb631c0b53368c1893bd96cf76422d257f7997a11f6466"
-- Upstream publishes release tarballs without signatures; the hash below
-- matches the one Arch Linux pins for the same tarball.

metadata({
	name = "popt",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Command line option parsing library",
	website = "https://github.com/rpm-software-management/popt",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The RPM Project",
		website = "https://rpm.org",
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
	local tarball = "popt-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://ftp.osuosl.org/pub/rpm/popt/releases/popt-1.x"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "popt-$VER.tar.gz"
		echo "$SHA512  popt-$VER.tar.gz" | sha512sum -c -
	]])
	sh([[tar -xf "popt-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "popt-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "popt-$VER"
		make DESTDIR="$ROOT" install
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/popt/$(basename "$f")"
		done
		true
	]])
end

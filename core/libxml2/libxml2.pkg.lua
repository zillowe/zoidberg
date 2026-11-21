local version = ZOI.VERSION or "2.15.4"
local sha512 = "e162ed16ad6fb6c6ef1c40c6bed66a5f76db177fc24410cc261c9ddc6b19e9b003315db67f67cbcadaf08e546f0672de87bf6f297014af50fe544a781647f584"
-- GNOME publishes release tarballs with SHA-256 checksums but no
-- signatures; the hash below was checked against it.

metadata({
	name = "libxml2",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "XML C parser and toolkit",
	website = "https://gitlab.gnome.org/GNOME/libxml2",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The GNOME Project",
		website = "https://gitlab.gnome.org/GNOME/libxml2",
	},
	bins = { "xmllint", "xmlcatalog" },
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
					"pacman:meson",
					"pacman:ninja",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/zlib",
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
	local tarball = "libxml2-" .. version .. ".tar.xz"
	sh([[
		fetch() {
			for base in \
				"https://download.gnome.org/sources/libxml2/2.15"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libxml2-$VER.tar.xz"
		echo "$SHA512  libxml2-$VER.tar.xz" | sha512sum -c -
	]])
	sh([[tar -xf "libxml2-$VER.tar.xz"]])
end

function build()
	sh([[
		cd "libxml2-$VER"
		meson setup _build \
			--prefix=/usr \
			--buildtype=plain \
			-Ddefault_library=shared \
			-Dicu=disabled \
			-Dhistory=disabled \
			-Dreadline=disabled \
			-Dpython=disabled \
			-Dlegacy=enabled \
			-Dzlib=enabled
		meson compile -C _build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libxml2-$VER"
		meson install -C _build --destdir "$ROOT"
		for f in Copyright; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libxml2/$(basename "$f")"
		done
		true
	]])
end

local version = ZOI.VERSION or "3.0.10"

metadata({
	name = "pkgconf",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Package compiler and linker metadata toolkit",
	website = "https://github.com/pkgconf/pkgconf",
	license = "ISC",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The pkgconf developers",
		website = "https://github.com/pkgconf/pkgconf",
	},
	bins = {
		"pkgconf",
		"pkg-config",
		"x86_64-pc-linux-gnu-pkg-config",
		"i686-pc-linux-gnu-pkg-config",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "pkg-config", "pkgconfig" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:gcc",
					"pacman:git",
					"pacman:meson",
					"pacman:ninja",
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
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d pkgconf ]; then
			git clone --depth 1 --branch "pkgconf-$VER" https://github.com/pkgconf/pkgconf.git pkgconf
		fi
	]])
end

function build()
	-- Same defaults as a distribution meson build
	sh([[
		rm -rf build
		meson setup \
			--prefix /usr \
			--libexecdir lib \
			--sbindir bin \
			--buildtype plain \
			--auto-features enabled \
			--wrap-mode nodownload \
			-D b_pie=true \
			pkgconf build
		meson compile -C build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		meson install -C build --destdir "$ROOT"

		for p in "$PKGLUADIR"/*.personality; do
			name="$(basename "$p")"
			install -Dm644 "$p" -t "$ROOT/usr/share/pkgconfig/personality.d"
			ln -sf pkgconf "$ROOT/usr/bin/${name%.*}-pkg-config"
		done

		ln -sf pkgconf "$ROOT/usr/bin/pkg-config"
		ln -sf pkgconf.1 "$ROOT/usr/share/man/man1/pkg-config.1"

		install -Dm644 pkgconf/COPYING -t "$ROOT/usr/share/licenses/pkgconf"
	]])
end

function test()
	cmd([[
		/usr/bin/pkgconf --version || pkgconf --version
	]])
end

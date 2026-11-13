local version = ZOI.VERSION or "0.13.1"

metadata({
	name = "bubblewrap",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Unprivileged sandboxing tool",
	website = "https://github.com/containers/bubblewrap",
	license = "LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Bubblewrap developers",
		website = "https://github.com/containers/bubblewrap",
	},
	bins = { "bwrap" },
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
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:bash-completion",
					"pacman:docbook-xsl",
					"pacman:gcc",
					"pacman:git",
					"pacman:libcap",
					"pacman:libxslt",
					"pacman:meson",
					"pacman:ninja",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/glibc",
			"zoi:@core/libcap",
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
		if [ ! -d bubblewrap ]; then
			git clone --depth 1 --branch "v$VER" https://github.com/containers/bubblewrap.git bubblewrap
		fi
	]])
end

function build()
	-- assume_kernel: oldest kernel bwrap may run on (major.minor.0). Kept at
	-- the same conservative baseline Arch uses, so older retained kernels
	-- still work.
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
			-D assume_kernel=6.18.0 \
			-D selinux=disabled \
			bubblewrap build
		meson compile -C build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		meson install -C build --destdir "$ROOT"
	]])
end

function test()
	cmd([[
		/usr/bin/bwrap --version || bwrap --version
	]])
end

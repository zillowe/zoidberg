local version = ZOI.VERSION or "1.1.0"

local function get_zig_target()
	local os = SYSTEM.OS
	local arch = SYSTEM.ARCH
	if arch == "amd64" then
		arch = "x86_64"
	elseif arch == "arm64" then
		arch = "aarch64"
	end
	return arch .. "-" .. os
end

metadata({
	name = "zsm",
	repo = "zillowe",
	version = version,
	revision = "1",
	description = "Modern, security-first replacement for shell-based installation scripts",
	website = "https://zillowe.qzz.io/docs/zds/zsm",
	git = "https://gitlab.com/zillowe/zillwen/zusty/zsm",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	license = "Apache-2.0",
	bins = { "zsm" },
	types = { "source" },
	tags = { "zillowe", "cli", "script-manager" },
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:zig", "pacman:git" },
			},
		},
	},
})

function prepare()
	if BUILD_TYPE == "source" then
		cmd("git clone " .. PKG.git .. " source")
		cmd("cd " .. BUILD_DIR .. "/source && zig build --release=small -Dtarget=" .. get_zig_target())
	end
end

function package()
	if BUILD_TYPE == "source" then
		local bin_name = "zsm"
		if SYSTEM.OS == "windows" then
			bin_name = "zsm.exe"
		end
		zcp("source/zig-out/bin/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end

function verify()
	return true
end

function uninstall() end

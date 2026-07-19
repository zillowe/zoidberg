local repo_owner = "zillowe"
local repo_name = "hello"
local version = ZOI.VERSION or "5.0.0"
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"

-- local function get_zig_target()
-- 	local os = SYSTEM.OS
-- 	local arch = SYSTEM.ARCH
-- 	if arch == "amd64" then
-- 		arch = "x86_64"
-- 	elseif arch == "arm64" then
-- 		arch = "aarch64"
-- 	end
-- 	return arch .. "-" .. os
-- end

metadata({
	name = "hello",
	repo = "zillowe",
	version = version,
	revision = "10",
	description = "Hello World",
	website = "https://github.com/zillowe/hello",
	git = git_url,
	man = "https://raw.githubusercontent.com/zillowe/hello/refs/heads/main/app/man.md",
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
	bins = { "hello" },
	types = { "source" },
	platforms = { "linux" },
	tags = { "zillowe", "example", "hello", "cli" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:zig",
					"pacman:git",
				},
			},
		},
	},
})

function prepare()
	if BUILD_TYPE == "source" then
		cmd("git clone --depth 1 --branch " .. "v" .. version .. " " .. PKG.git .. " source")
		-- cmd("cd " .. BUILD_DIR .. "/source && zig build --release=small -Dtarget=" .. get_zig_target())
	end
end

function build()
	if BUILD_TYPE == "source" then
		cmd("cd " .. BUILD_DIR .. "/source && zig build --release=small -Dtarget=x86_64-linux")
	end
end

function package()
	if BUILD_TYPE == "source" then
		local bin_name = "hello"
		zcp("source/zig-out/bin/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end

function verify()
	return true
end

function uninstall() end

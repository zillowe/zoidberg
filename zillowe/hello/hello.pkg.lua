local repo_owner = "Zillowe"
local repo_name = "Hello"
local version = ZOI.VERSION or "3.0.0"
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"
local release_base_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. "/releases/download/v" .. version

local platform_map = {
	macos = "darwin",
}

local function get_mapped_platform()
	local current_platform = SYSTEM.OS .. "-" .. SYSTEM.ARCH
	return platform_map[current_platform] or platform_map[SYSTEM.OS] or current_platform
end

local function get_mapped_os()
	return get_mapped_platform():match("([^-]+)")
end

metadata({
	name = "hello",
	repo = "zillowe",
	version = version,
	description = "Hello World",
	website = "https://github.com/Zillowe/Hello",
	git = git_url,
	man = "https://raw.githubusercontent.com/Zillowe/Hello/refs/heads/main/app/man.md",
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
	conflicts = { "hello" },
	types = { "source", "pre-compiled" },
})

dependencies({
	build = {
		source = {
			required = { "native:zig" },
		},
	},
})

function prepare()
	if BUILD_TYPE == "pre-compiled" then
		local ext
		if SYSTEM.OS == "windows" then
			ext = "zip"
		else
			ext = "tar.xz"
		end
		local file_name = "hello-" .. get_mapped_os() .. "-" .. SYSTEM.ARCH .. "." .. ext
		local url = release_base_url .. "/" .. file_name

		UTILS.EXTRACT(url, "precompiled")
	elseif BUILD_TYPE == "source" then
		cmd("git clone " .. PKG.git .. " " .. BUILD_DIR .. "/source")
		cmd("cd " .. BUILD_DIR .. "/source && zig build-exe main.zig -O ReleaseSmall --name hello")
	end
end

function package()
	local bin_name = "hello"
	if SYSTEM.OS == "windows" then
		bin_name = "hello.exe"
	end

	if BUILD_TYPE == "pre-compiled" then
		local bin_path = UTILS.FIND.file("precompiled", bin_name)
		if bin_path then
			zcp(bin_path, "${pkgstore}/bin/" .. bin_name)
		else
			error("Could not find '" .. bin_name .. "' in pre-compiled archive.")
		end
	elseif BUILD_TYPE == "source" then
		zcp("source/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end

function verify()
	return true
end

function uninstall() end

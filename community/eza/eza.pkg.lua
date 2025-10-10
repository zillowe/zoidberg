local repo_owner = "eza-community"
local repo_name = "eza"
local version = SYSTEM.VERSION or "0.23.4" -- Use a real latest version as default
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"

local bins = { "eza" }
if SYSTEM.OS == "windows" then
	bins = { "eza.exe" }
end

metadata({
	name = repo_name,
	repo = "community",
	version = version,
	description =
	"eza is a modern alternative for the venerable file-listing command-line program ls that ships with Unix and Linux operating systems, giving it more features and better defaults",
	website = "https://eza.rocks/",
	git = git_url,
	maintainer = {
		name = "Zillowe Community",
		website = "https://gitlab.com/Zillowe/Zillwen/Zusty/Zoidberg",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Christina Sørensen",
		email = "christina@cafkafk.com",
	},
	license = "MIT",
	bins = bins,
	conflicts = { "eza", "exa" },
	types = { "prebuilt", "source" },
})

dependencies({
	build = {
		required = { "native:cargo" },
	},
})

function prepare()
	if BUILD_TYPE == "prebuilt" then
		local arch = SYSTEM.ARCH
		if arch == "amd64" then
			arch = "x86_64"
		elseif arch == "arm64" then
			arch = "aarch64"
		end

		local os = SYSTEM.OS
		if os == "macos" then
			os = "darwin"
		end

		local platform_key = arch .. "-" .. os
		local platform_map = {
			["x86_64-linux"] = "x86_64-unknown-linux-gnu",
			["aarch64-linux"] = "aarch64-unknown-linux-gnu",
			["x86_64-windows"] = "x86_64-pc-windows-gnu",
		}
		local target = platform_map[platform_key]
		if not target then
			error("Unsupported platform for prebuilt binary: " .. platform_key)
		end

		local extension = ".tar.gz"
		if platform_key == "x86_64-windows" then
			extension = ".zip"
		end

		local asset_name = "eza-" .. target .. extension
		local url = "https://github.com/"
				.. repo_owner
				.. "/"
				.. repo_name
				.. "/releases/download/v"
				.. PKG.version
				.. "/"
				.. asset_name

		UTILS.EXTRACT(url, "prebuilt")
	end
end

function package()
	local bin_name = "eza"
	if SYSTEM.OS == "windows" then
		bin_name = "eza.exe"
	end

	if BUILD_TYPE == "prebuilt" then
		local bin_path = UTILS.FIND.file("prebuilt", bin_name)
		if bin_path then
			zcp(bin_path, "${pkgstore}/bin/" .. bin_name)
		else
			error("Could not find '" .. bin_name .. "' binary in extracted archive")
		end
	elseif BUILD_TYPE == "source" then
		cmd("cargo build --release")
		zcp("target/release/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end

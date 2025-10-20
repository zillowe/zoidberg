local repo_owner = "athasdev"
local repo_name = "athas"
local version = ZOI.VERSION or "0.1.2"
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"
local release_base_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. "/releases/download/v" .. version

metadata({
	name = "athas",
	repo = "extra",
	version = version,
	description = "A lightweight code editor.",
	website = "https://athas.dev",
	git = git_url,
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Athas Industries",
		website = "https://athas.dev",
		email = "hey@athas.dev",
	},
	license = "Apache-2.0",
	bins = { "athas" },
	conflicts = { "athas" },
	types = { "pre-compiled" },
})

function prepare()
	if BUILD_TYPE == "pre-compiled" then
		local os = SYSTEM.OS
		local arch = SYSTEM.ARCH
		local file_name
		local is_archive = false

		if os == "linux" and arch == "amd64" then
			file_name = "Athas_" .. PKG.version .. "_amd64.deb"
		elseif os == "macos" and arch == "amd64" then
			file_name = "Athas_x64.app.tar.gz"
			is_archive = true
		elseif os == "macos" and arch == "arm64" then
			file_name = "Athas_aarch64.app.tar.gz"
			is_archive = true
		elseif os == "windows" and arch == "amd64" then
			file_name = "Athas_" .. PKG.version .. "_x64-setup.exe"
		else
			error("Unsupported platform for pre-compiled binary: " .. os .. "-" .. arch)
		end

		local url = release_base_url .. "/" .. file_name
		print("Downloading from: " .. url)

		cmd('curl -L -o "' .. file_name .. '" "' .. url .. '"')

		if is_archive then
			UTILS.EXTRACT(file_name, "extracted")
		elseif os == "linux" then
			cmd('"ar x "' .. file_name .. '"')
			cmd('"tar -xf data.tar.gz')
		end
	end
end

function package()
	if BUILD_TYPE == "pre-compiled" then
		local os = SYSTEM.OS
		local arch = SYSTEM.ARCH

		if os == "linux" and arch == "amd64" then
			zcp("usr/bin/athas", "${pkgstore}/bin/athas")
			zcp("usr/share", "${usrroot}/usr/share")
		elseif os == "macos" then
			local bin_name = "athas"
			local source_path = "extracted/Athas.app/Contents/MacOS/Athas"
			zcp(source_path, "${pkgstore}/bin/" .. bin_name)
		elseif os == "windows" and arch == "amd64" then
			local bin_name = "athas"
			local source_path = "Athas_" .. PKG.version .. "_x64-setup.exe"
			zcp(source_path, "${pkgstore}/bin/" .. bin_name .. ".exe")
		end
	end
end

function verify()
	return true
end

function uninstall() end

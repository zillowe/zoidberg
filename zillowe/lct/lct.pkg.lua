local version = ZOI.VERSION or "1.1.1"

local function get_go_env()
	local os = SYSTEM.OS
	local arch = SYSTEM.ARCH
	return "GOOS=" .. os .. " GOARCH=" .. arch
end

metadata({
	name = "lct",
	repo = "zillowe",
	version = version,
	revision = "6",
	description = "Command-line tool for easily adding open-source licenses to your projects",
	website = "https://zillowe.qzz.io/docs/zds/lct",
	git = "https://gitlab.com/zillowe/zillwen/zusty/lct",
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
	bins = { "lct" },
	types = { "source" },
	platforms = { "linux" },
	tags = { "zillowe", "license", "cli" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:go",
					"pacman:git",
					"brew:go",
					"brew:git",
					"choco:golang",
					"choco:git",
				},
			},
		},
	},
})

function verify()
	return true
end

function prepare()
	if BUILD_TYPE == "source" then
		cmd("git clone --depth 1 --branch " .. "v" .. version .. " " .. PKG.git .. " source")
	end
end

function package()
	if BUILD_TYPE == "source" then
		if SYSTEM.OS == "windows" then
			cmd("cd source && " .. get_go_env() .. " ./build/build-release.ps1")
		else
			cmd("cd source && " .. get_go_env() .. " ./build/build-release.sh")
		end
		local bin_name = "lct"
		if SYSTEM.OS == "windows" then
			bin_name = "lct.exe"
		end
		zcp("source/build/compiled/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end

function uninstall() end

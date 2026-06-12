local version = ZOI.VERSION or "1.4.0"

local function get_go_env()
	local os = SYSTEM.OS
	local arch = SYSTEM.ARCH
	return "GOOS=" .. os .. " GOARCH=" .. arch
end

metadata({
	name = "gct",
	repo = "zillowe",
	version = version,
	revision = "2",
	description = "An intelligent, AI-powered Git assistant",
	website = "https://zillowe.qzz.io/docs/zds/gct",
	git = "https://gitlab.com/zillowe/zillwen/zusty/gct",
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
	bins = { "gct" },
	types = { "source" },
	tags = { "zillowe", "ai", "git", "cli" },
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:go", "pacman:git" },
			},
		},
	},
	runtime = {
		required = { "native:git" },
	},
})

function verify()
	return true
end

function prepare()
	if BUILD_TYPE == "source" then
		cmd("git clone " .. PKG.git .. " source")
	end
end

function package()
	if BUILD_TYPE == "source" then
		cmd("cd source && " .. get_go_env() .. " ./build/build-release.sh")
		local bin_name = "gct"
		if SYSTEM.OS == "windows" then
			bin_name = "gct.exe"
		end
		zcp("source/build/compiled/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end

function uninstall() end

local version = ZOI.VERSION or "1.4.1"

local function get_go_env()
	local os = SYSTEM.OS
	local arch = SYSTEM.ARCH
	return "GOOS=" .. os .. " GOARCH=" .. arch
end

metadata({
	name = "gct",
	repo = "zillowe",
	version = version,
	revision = "11",
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
	platforms = { "linux" },
	tags = { "zillowe", "ai", "git", "cli" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:go",
					"pacman:git",
				},
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
		cmd("git clone --depth 1 --branch " .. "v" .. version .. " " .. PKG.git .. " source")
	end
end

function build()
	if BUILD_TYPE == "source" then
		cmd("cd source && " .. get_go_env() .. " ./build/build-release.sh")
	end
end

function package()
	if BUILD_TYPE == "source" then
		zcp("source/build/compiled/gct", "${pkgstore}/bin/gct")
	end
end

function uninstall() end

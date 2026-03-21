local version = ZOI.VERSION or "1.3.0"

metadata({
	name = "gct",
	repo = "zillowe",
	version = version,
	description = "An intelligent, AI-powered Git assistant",
	website = "https://zillowe.qzz.io/docs/zds/gct",
	git = "https://github.com/Zillowe/GCT.git",
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
	conflicts = { "gct" },
	types = { "source" },
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
		cmd("cd source && ./build/build-release.sh")
		zcp("source/build/compiled/gct", "${pkgstore}/bin/gct")
	end
end

function uninstall() end

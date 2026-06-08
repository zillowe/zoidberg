local version = ZOI.VERSION or "1.1.0"

metadata({
	name = "lct",
	repo = "zillowe",
	version = version,
	description = "Command-line tool for easily adding open-source licenses to your projects.",
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
	tags = { "zillowe", "lct", "license", "cli" },
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:go", "pacman:git" },
			},
		},
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
		zcp("source/build/compiled/lct", "${pkgstore}/bin/lct")
	end
end

function uninstall() end

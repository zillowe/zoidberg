local version = ZOI.VERSION or "1.0.0"

metadata({
	name = "zsm",
	repo = "zillowe",
	version = version,
	description = "Modern, security-first replacement for bash-based installation scripts",
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
	tags = { "cli", "script-manager", "zillowe" },
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:zig" },
			},
		},
	},
})

function prepare()
	if BUILD_TYPE == "source" then
		cmd("git clone " .. PKG.git .. " source")
		cmd("cd " .. BUILD_DIR .. "/source && zig build --release=small")
	end
end

function package()
	if BUILD_TYPE == "source" then
		zcp("source/zig-out/bin/zsm", "${pkgstore}/bin/zsm")
	end
end

function verify()
	return true
end

function uninstall() end

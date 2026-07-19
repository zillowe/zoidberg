local version = ZOI.VERSION or "0.2.0"

metadata({
	name = "zoko",
	repo = "zillowe",
	version = version,
	revision = "4",
	description = "A JSON-like format for data storing",
	website = "https://zillowe.qzz.io/docs/akuolwa/zoko",
	git = "https://gitlab.com/zillowe/zillowex/akuolwa/zoko",
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
	bins = { "zoko-cli" },
	types = { "source" },
	tags = { "zillowe", "language", "cli" },
	platforms = { "linux" },
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:rust", "pacman:git" },
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
		cmd("cd source && cargo build --release -p zoko-cli")
		zcp("source/target/release/zoko-cli", "${pkgstore}/bin/zoko-cli")
	end
end

function uninstall() end

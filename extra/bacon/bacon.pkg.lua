local version = ZOI.VERSION or "3.23.0"

metadata({
	name = "bacon",
	repo = "extra",
	version = version,
	revision = "9",
	description = "A background rust code checker",
	website = "https://dystroy.org/bacon",
	git = "https://github.com/Canop/bacon.git",
	license = "AGPL-3.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Denys Séguret",
		website = "https://dystroy.org",
	},
	bins = { "bacon" },
	types = { "source" },
	platforms = { "linux" },
	tags = { "rust", "code-checker", "cli" },
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:rust", "pacman:git" },
			},
		},
	},
	runtime = {
		optional = {
			"native:cargo: for use with Rust",
			"native:clang: for use with C++ via clang",
			"native:gcc: for use with C++ via gcc",
			"native:eslint: for use with JavaScript",
			"native:python: for use with Python via unittest",
		},
	},
})

function prepare()
	cmd("git clone --depth 1 --branch " .. "v" .. version .. " " .. PKG.git .. " source")
	cmd("cd source && cargo fetch --locked")
end

function build()
	cmd("cd source && cargo build --release --locked")
end

function package()
	local build_bin = "source/target/release/bacon"
	zcp(build_bin, "${pkgstore}/bin/bacon")

	zdoc("source/README.md")
	zdoc("source/CHANGELOG.md")
	if UTILS.FS.exists("source/doc") then
		zdoc("source/doc")
	end

	zlicense("source/LICENSE")
end

function uninstall() end

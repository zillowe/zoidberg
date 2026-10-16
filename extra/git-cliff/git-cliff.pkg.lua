local version = ZOI.VERSION or "2.14.2"

metadata({
	name = "git-cliff",
	repo = "extra",
	version = version,
	revision = "1",
	description = "A highly customizable changelog generator",
	git = "https://github.com/orhun/git-cliff",
	website = "https://git-cliff.org",
	license = "MIT OR Apache-2.0",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Orhun Parmaksız",
		website = "https://orhun.dev",
	},
	bins = { "git-cliff" },
	types = { "source" },
	platforms = { "linux-amd64" },
	tags = { "rust", "git", "cli", "changelog" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:rust",
					"pacman:pkgconf",
					"pacman:libgit2",
					"pacman:zlib",
					"pacman:git",
				},
			},
		},
	},
})

function prepare()
	cmd("git clone --depth 1 --branch " .. "v" .. version .. " " .. PKG.git .. " source")
	cmd("cd source")
	cmd("cargo fetch --locked")
end

function build()
	cmd("export LIBGIT2_NO_VENDOR=1")
	cmd("cd source")
	cmd(
		"cargo build --release --frozen --no-default-features --features github --features gitlab --features bitbucket --features gitea"
	)
	cmd("OUT_DIR=source/completions/ ./target/release/git-cliff-completions")
	cmd("OUT_DIR=source/man/ ./target/release/git-cliff-mangen")
end

function package()
	zcp("source/target/release/git-cliff", "${pkgstore}/bin/git-cliff")

	zdoc("source/README.md")
	zlicense("source/LICENSE-MIT")

	zshell("source/completions/git-cliff.bash", "bash")
	zshell("source/completions/git-cliff.fish", "fish")
	zshell("source/completions/_git-cliff", "zsh")

	zman("source/man/git-cliff.1")
end

function uninstall() end

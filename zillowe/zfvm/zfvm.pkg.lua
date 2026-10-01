local version = ZOI.VERSION or "0.1.0"

metadata({
	name = "zfvm",
	repo = "zillowe",
	version = version,
	revision = "2",
	description = "A Rust implementation of the ZF Versioning Method (ZFVM).",
	website = "https://zillowe.qzz.io/docs/akuolwa/zfvm",
	git = "https://gitlab.com/zillowe/zillowex/akuolwa/zfvm",
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
	bins = { "zfvm" },
	types = { "source" },
	tags = { "zillowe", "version", "cli" },
	platforms = { "linux-amd64" },
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:rust", "pacman:git", "pacman:asciidoctor" },
			},
		},
	},
})

function verify()
	return true
end

function prepare()
	cmd("git clone --depth 1 --branch " .. "v" .. version .. " " .. PKG.git .. " source")
	cmd("cd source")
	cmd("cargo fetch --locked")
end

function build()
	cmd("cd source")
	cmd("cargo build --release --locked -p zfvm-cli")
	cmd("asciidoctor --backend manpage --out-file man/zfvm.1 man/zfvm.adoc")
	cmd("asciidoctor --backend manpage --out-file man/zfvm.3 man/zfvm-lib.adoc")
end

function package()
	zcp("source/target/release/zfvm", "${pkgstore}/bin/zfvm")
	zman("source/man/zfvm.1")
	zman("source/man/zfvm.3")
end

function uninstall() end

local version = ZOI.VERSION or "1.6.2"

metadata({
	name = "zbsdiff",
	repo = "zillowe",
	version = version,
	revision = "1",
	description = "Fast and memory saving bsdiff 4.x compatible delta compressor and patcher, fork of qbsdiff.",
	website = "https://zillowe.qzz.io/docs/akuolwa/zbsdiff",
	git = "https://gitlab.com/zillowe/zillowex/akuolwa/zbsdiff",
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
	bins = { "zbsdiff", "zbspatch" },
	types = { "source" },
	tags = { "zillowe", "bsdiff", "cli" },
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
	cmd("cargo build --release --locked -p zbsdiff-cli")
	cmd("asciidoctor --backend manpage --out-file man/zbsdiff.1 man/zbsdiff.adoc")
	cmd("asciidoctor --backend manpage --out-file man/zbspatch.1 man/zbspatch.adoc")
	cmd("asciidoctor --backend manpage --out-file man/zbsdiff.3 man/zbsdiff-lib.adoc")
end

function package()
	zcp("source/target/release/zbsdiff", "${pkgstore}/bin/zbsdiff")
	zcp("source/target/release/zbspatch", "${pkgstore}/bin/zbspatch")
	zman("source/man/zbsdiff.1")
	zman("source/man/zbspatch.1")
	zman("source/man/zbsdiff.3")
end

function uninstall() end

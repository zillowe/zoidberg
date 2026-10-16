local version = ZOI.VERSION or "0.1.1"

metadata({
	name = "zync",
	repo = "zillowe",
	version = version,
	revision = "1",
	description = "rsync over HTTP, with bsdiff residue reduction",
	website = "https://zillowe.qzz.io/docs/akuolwa/zync",
	git = "https://gitlab.com/zillowe/zillowex/akuolwa/zync",
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
	bins = { "zync", "zyncmake" },
	types = { "source" },
	tags = { "zillowe", "sync", "cli" },
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
	cmd("cargo build --release --locked -p zync-cli")
	cmd("asciidoctor --backend manpage --out-file man/zync.1 man/zync.adoc")
	cmd("asciidoctor --backend manpage --out-file man/zyncmake.1 man/zyncmake.adoc")
	cmd("asciidoctor --backend manpage --out-file man/zync.3 man/zync-lib.adoc")
end

function package()
	zcp("source/target/release/zync", "${pkgstore}/bin/zync")
	zcp("source/target/release/zyncmake", "${pkgstore}/bin/zyncmake")
	zman("source/man/zync.1")
	zman("source/man/zyncmake.1")
	zman("source/man/zync.3")
end

function uninstall() end

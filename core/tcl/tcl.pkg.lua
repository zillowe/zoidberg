local version = ZOI.VERSION or "9.1.0"
local sha512 = "0084416213204e289d17e0b5c0c11f741ce744e8b8a12ba7d5c66c34c8f332a4b57e8da43fa5b576267e3902d5fdafd8e2082b0afde0241b2c40b546810e7b5e"
-- Tcl does not sign releases. This is upstream's "tcl-core" tarball (Tcl
-- without the bundled extension packages in pkgs/). sha512 computed from
-- the downloaded file; its sha1 matches the one SourceForge publishes for
-- it (394f2bd19e6f82e919dfa15db5d15fcfae73ab5f).

local branch = string.match(version, "^(%d+%.%d+)")

metadata({
	name = "tcl",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Powerful, easy-to-learn dynamic programming language",
	website = "https://www.tcl-lang.org/",
	license = "TCL",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Tcl Core Team",
		website = "https://www.tcl-lang.org/",
	},
	bins = { "tclsh" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:sed",
					"pacman:tar",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, BRANCH = branch, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://downloads.sourceforge.net/project/tcl/Tcl/$VER" \
				"https://prdownloads.sourceforge.net/tcl"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "tcl-core$VER-src.tar.gz"
		echo "$SHA512  tcl-core$VER-src.tar.gz" | sha512sum -c -
		tar -xf "tcl-core$VER-src.tar.gz"
		# Arch drops the bundled SQLite package (sqlite ships its own Tcl
		# extension); tcl-core normally has none, this just makes sure.
		rm -rf "tcl$VER"/pkgs/sqlite3*
	]],
		opts
	)
end

function build()
	-- Options as Arch. Arch builds with -j1.
	cmd(
		[[
		cd "tcl$VER/unix"
		./configure \
			--prefix=/usr \
			--mandir=/usr/share/man \
			--enable-threads \
			--enable-64bit
		make -j1
	]],
		opts
	)
end

function package()
	-- Point tclConfig.sh at the installed locations instead of the build
	-- tree, as Arch does.
	cmd(
		[[
		SRC="$(pwd)/tcl$VER"
		cd "$SRC/unix"
		make INSTALL_ROOT="$ROOT" install install-private-headers
		ln -sf "tclsh$BRANCH" "$ROOT/usr/bin/tclsh"
		ln -sf "libtcl$BRANCH.so" "$ROOT/usr/lib/libtcl.so"
		install -Dm644 tcl.m4 -t "$ROOT/usr/share/aclocal"
		chmod 644 "$ROOT"/usr/lib/libtclstub*.a
		sed -e "s#$SRC/unix#/usr/lib#" \
			-e "s#$SRC#/usr/include#" \
			-i "$ROOT/usr/lib/tclConfig.sh"
	]],
		opts
	)
	zlicense("tcl" .. version .. "/license.terms")
	zdoc("tcl" .. version .. "/README.md")
	zdoc("tcl" .. version .. "/changes.md")
end

function test()
	cmd([[
		echo 'puts [info patchlevel]' | /usr/bin/tclsh
	]])
end

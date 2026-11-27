local version = ZOI.VERSION or "3.54.1"
local sha512 = "1c728b93da228d2c135096a5896728934d7d3eda4bdaa2dd05bb02812691ed56c8a4a9181b3b00215f5849d5cd8a191a7cbbc132f11b1fa2ebb6f8abaa92c677"
-- SQLite does not sign releases. The hash is Gentoo's (same file, same
-- size as listed on sqlite.org/download.html, whose SHA3-256 for it is
-- 877c6f4996ce7adb368686bce21638de9e3d91534832ad3d9d119037d1bc22ad), and the
-- previously pinned sha256 (387e7f6c...c71b) matches Arch's.
-- sqlite.org groups source archives by release year
local release_year = "2026"

local function src_version(v)
	local major, minor, patch = string.match(v, "^(%d+)%.(%d+)%.(%d+)")
	return string.format("%d%02d%02d00", tonumber(major), tonumber(minor), tonumber(patch))
end
local srcver = src_version(version)

metadata({
	name = "sqlite",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "A C library that implements an SQL database engine",
	website = "https://www.sqlite.org/",
	license = "blessing",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The SQLite developers",
		website = "https://www.sqlite.org/",
	},
	bins = {
		"dbdump",
		"dbhash",
		"dbtotxt",
		"index_usage",
		"showdb",
		"showjournal",
		"showshm",
		"showstat4",
		"showwal",
		"sqldiff",
		"sqlite3",
		"sqlite3_expert",
		"sqlite3_rsync",
	},
	-- Binaries of sub-packages other than the ones above.
	sub_bins = {
		tcl = { "sqltclsh" },
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "sqlite3" },
	-- tcl: the Tcl extension (TEA) and sqltclsh, Arch's sqlite-tcl.
	sub_packages = { "main", "tcl" },
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:readline",
					"pacman:tcl",
					"pacman:unzip",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		sub_packages = {
			main = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/readline",
					"zoi:@core/zlib",
				},
			},
			tcl = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/sqlite",
					"zoi:@core/tcl",
					"zoi:@core/zlib",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { SRCVER = srcver, YEAR = release_year, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.sqlite.org/$YEAR" \
				"https://www2.sqlite.org/$YEAR" \
				"https://www3.sqlite.org/$YEAR"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "sqlite-src-$SRCVER.zip"
		echo "$SHA512  sqlite-src-$SRCVER.zip" | sha512sum -c -
		unzip -q "sqlite-src-$SRCVER.zip"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		export CFLAGS="$(printf '%s' "${CFLAGS:-}" | sed 's/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2/')"
		export CXXFLAGS="$(printf '%s' "${CXXFLAGS:-}" | sed 's/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2/')"
		export CPPFLAGS="${CPPFLAGS:-} \
			-DSQLITE_ENABLE_COLUMN_METADATA=1 \
			-DSQLITE_ENABLE_UNLOCK_NOTIFY \
			-DSQLITE_ENABLE_DBSTAT_VTAB=1 \
			-DSQLITE_ENABLE_FTS3_PARENTHESIS \
			-DSQLITE_SECURE_DELETE \
			-DSQLITE_ENABLE_STMTVTAB \
			-DSQLITE_ENABLE_STAT4 \
			-DSQLITE_MAX_VARIABLE_NUMBER=250000 \
			-DSQLITE_MAX_EXPR_DEPTH=10000 \
			-DSQLITE_ENABLE_MATH_FUNCTIONS"

		cd "sqlite-src-$SRCVER"
		./configure --prefix=/usr \
			--disable-static \
			--enable-session \
			--enable-fts3 \
			--fts4 \
			--fts5 \
			--rtree \
			--soname=legacy

		sed -i -e 's/$(LDFLAGS.libsqlite3)/ -Wl,-O1,--as-needed \0/g' main.mk
		make -j"$(nproc)"
		make -j"$(nproc)" dbdump dbhash dbtotxt index_usage showdb showjournal showshm \
			showstat4 showwal sqldiff sqlite3_expert sqlite3_rsync sqltclsh
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	-- Install once into a scratch tree, then split it between sub-packages.
	cmd(
		[[
		DEST="$(pwd)/sqlite-dest"
		if [ ! -d "$DEST" ]; then
			make -C "sqlite-src-$SRCVER" DESTDIR="$DEST" install
		fi
	]],
		opts
	)

	if sub == "tcl" then
		-- The extension directory (holding pkgIndex.tcl) is wherever the
		-- build host's Tcl wants packages, e.g. /usr/lib/tcl9.0/sqlite3.x.
		cmd(
			[[
			DEST="$(pwd)/sqlite-dest"
			ext="$(find "$DEST/usr/lib" -name pkgIndex.tcl -path '*sqlite*' -printf '%h\n')"
			[ -n "$ext" ] || { echo "sqlite Tcl extension was not built" >&2; exit 1; }
			rel="${ext#"$DEST"/}"
			mkdir -p "$ROOT/$(dirname "$rel")" "$ROOT/usr/bin"
			cp -a "$ext" "$ROOT/$rel"
			install -m755 "sqlite-src-$SRCVER/sqltclsh" "$ROOT/usr/bin/"
		]],
			opts
		)
	else
		cmd(
			[[
			DEST="$(pwd)/sqlite-dest"
			mkdir -p "$ROOT"
			cp -a "$DEST/." "$ROOT/"
			# The Tcl extension is the tcl sub-package
			find "$ROOT/usr/lib" -name pkgIndex.tcl -path '*sqlite*' -printf '%h\n' | while read -r ext; do
				rm -rf "$ext"
			done
			find "$ROOT/usr/lib" -mindepth 1 -type d -empty -delete
			cd "sqlite-src-$SRCVER"
			install -m755 dbdump dbhash dbtotxt index_usage showdb showjournal showshm \
				showstat4 showwal sqldiff sqlite3_expert sqlite3_rsync "$ROOT/usr/bin/"
			install -dm755 "$ROOT/usr/share/man/man1"
			install -m644 sqlite3.1 "$ROOT/usr/share/man/man1/"
		]],
			opts
		)
	end
	-- SQLite is public domain; the text is sqlite.org's copyright page
	-- (as Arch's license.txt).
	zlicense("${pkgluadir}/files/license.txt")
end

function test()
	cmd([[
		/usr/bin/sqlite3 --version || sqlite3 --version
	]])
end

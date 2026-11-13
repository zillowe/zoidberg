local version = ZOI.VERSION or "3.54.1"
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
	revision = "2",
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
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "sqlite3" },
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
		required = {
			"zoi:@core/glibc",
			"zoi:@core/readline",
			"zoi:@core/zlib",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "SRCVER='" .. srcver .. "'\n"
		.. "YEAR='" .. release_year .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d "sqlite-src-$SRCVER" ]; then
			curl -sSfL "https://www.sqlite.org/$YEAR/sqlite-src-$SRCVER.zip" -o "sqlite-src-$SRCVER.zip"
			echo "387e7f6cad4797b17848c07d453dc6606917bb356a6cfe5a3abafd38c240c71b  sqlite-src-$SRCVER.zip" | sha256sum -c -
			unzip -q "sqlite-src-$SRCVER.zip"
		fi
	]])
end

function build()
	sh([[
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
			showstat4 showwal sqldiff sqlite3_expert sqlite3_rsync
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "sqlite-src-$SRCVER"
		make DESTDIR="$ROOT" install
		install -m755 dbdump dbhash dbtotxt index_usage showdb showjournal showshm \
			showstat4 showwal sqldiff sqlite3_expert sqlite3_rsync "$ROOT/usr/bin/"
		install -dm755 "$ROOT/usr/share/man/man1"
		install -m644 sqlite3.1 "$ROOT/usr/share/man/man1/"
		install -Dm644 "$PKGLUADIR/license.txt" "$ROOT/usr/share/licenses/sqlite/license.txt"

		# The Tcl extension is not shipped
		rm -rf "$ROOT"/usr/lib/tcl*
	]])
end

function test()
	cmd([[
		/usr/bin/sqlite3 --version || sqlite3 --version
	]])
end

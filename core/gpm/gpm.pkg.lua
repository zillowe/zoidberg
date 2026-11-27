local version = ZOI.VERSION or "1.20.7.r38.ge82d1a6"
local commit = "e82d1a653ca94aa4ed12441424da6ce780b1e530"
local sha512 = "d291041ddadf92d2078ef5e9a2a3cd30cfb95b5880cc034632c68ae10231edcdb039de767cb8886fd7e27cec5715bc10d1311e68b9cc4ecf654dd46670f5d298"
-- Upstream has not released since 1.20.7 (2012). As Arch Linux, this builds
-- the later git commit above; the source is GitHub's archive of it, pinned
-- by hash (its files were checked against the commit).

metadata({
	name = "gpm",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A mouse server for the console and xterm",
	website = "https://www.nico.schottelius.org/software/gpm/",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Alessandro Rubini, Nico Schottelius and the gpm contributors",
		website = "https://github.com/telmich/gpm",
	},
	bins = {
		"gpm",
		"disable-paste",
		"display-buttons",
		"display-coords",
		"get-versions",
		"gpm-root",
		"hltest",
		"mev",
		"mouse-test",
	},
	provides = { "libgpm.so" },
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
					-- autoconf, automake, libtool and texinfo for autogen.sh
					"pacman:base-devel",
					"pacman:gcc",
					"pacman:make",
					"pacman:ncurses",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
			-- pidof, used by /etc/profile.d/gpm.sh
			"zoi:@core/procps-ng",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { COMMIT = commit, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/telmich/gpm/archive/$COMMIT.tar.gz" \
			-o "gpm-$COMMIT.tar.gz"
		echo "$SHA512  gpm-$COMMIT.tar.gz" | sha512sum -c -
		tar -xf "gpm-$COMMIT.tar.gz"
		cd "gpm-$COMMIT"
		./autogen.sh
	]],
		opts
	)
end

function build()
	-- Options follow Arch Linux's PKGBUILD, including its serial make and
	-- gnu17 (the code predates C23, GCC 15's default).
	cmd(
		[[
		cd "gpm-$COMMIT"
		export CFLAGS="${CFLAGS:-} -std=gnu17"
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--sbindir=/usr/bin
		make -j1
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "gpm-$COMMIT"
		make -j1 DESTDIR="$ROOT" install
		install -Dm644 "$PKGLUADIR/files/gpm.sh" "$ROOT/etc/profile.d/gpm.sh"
		install -Dm644 "$PKGLUADIR/files/gpm.path" "$ROOT/usr/lib/systemd/system/gpm.path"
		install -Dm644 "$PKGLUADIR/files/gpm.service" "$ROOT/usr/lib/systemd/system/gpm.service"

		# As Arch Linux: the development link and executable library.
		cd "$ROOT/usr/lib"
		ln -s libgpm.so.2.* libgpm.so
		chmod 0755 "$ROOT"/usr/lib/libgpm.so.*
	]],
		opts
	)

	zlicense("gpm-" .. commit .. "/COPYING")
end

function test()
	cmd([["$ROOT/usr/bin/gpm" -v]], opts)
	return true
end

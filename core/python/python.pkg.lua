local version = ZOI.VERSION or "3.14.10"
local sha512 = "730ea64f7e8815a5e1a4280b1205d77719875de630e6807b3140987b44e7b91215918cf75ed77250cf6feb5de98ff4175555cbba96eaf32564d2f421e723994a"
-- Python 3.14 releases are signed with Sigstore only (PGP signatures stopped
-- with 3.14), which Zoi cannot verify. The hash was taken from Gentoo's
-- Manifest (which checks the .sigstore bundle) and matches Arch Linux's
-- sha512sums; the pinned hash is the trust anchor.

metadata({
	name = "python",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "The Python programming language",
	website = "https://www.python.org/",
	license = "PSF-2.0",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Python Software Foundation",
		website = "https://www.python.org/",
	},
	bins = {
		"pydoc",
		"pydoc3",
		"pydoc3.14",
		"python",
		"python-config",
		"python3",
		"python3-config",
		"python3.14",
		"python3.14-config",
	},
	provides = { "python3", "python-externally-managed" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	quiet = { "build" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:bluez-libs",
					"pacman:bzip2",
					"pacman:curl",
					"pacman:expat",
					"pacman:gcc",
					"pacman:gdbm",
					"pacman:libffi",
					"pacman:make",
					"pacman:mpdecimal",
					"pacman:ncurses",
					"pacman:openssl",
					"pacman:patch",
					"pacman:readline",
					"pacman:sqlite",
					"pacman:tar",
					"pacman:tzdata",
					"pacman:util-linux-libs",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bzip2",
			"zoi:@core/expat",
			"zoi:@core/gdbm",
			"zoi:@core/glibc",
			"zoi:@core/libffi",
			"zoi:@core/mpdecimal",
			"zoi:@core/ncurses",
			"zoi:@core/openssl",
			"zoi:@core/readline",
			"zoi:@core/sqlite",
			"zoi:@core/tzdata",
			"zoi:@core/util-linux:libs",
			"zoi:@core/xz",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = { VER = version, SHA512 = sha512, PYVER = version:match("^(%d+%.%d+)") },
}

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.python.org/ftp/python/$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "Python-$VER.tar.xz"
		echo "$SHA512  Python-$VER.tar.xz" | sha512sum -c -
		tar -xf "Python-$VER.tar.xz"
		cd "Python-$VER"

		# Use the system expat and libmpdec, not the copies in the tarball.
		rm -r Modules/expat
		rm -r Modules/_decimal/libmpdec

		# Build with POSIX 2024 (upstream commit 927eb448, as Arch Linux).
		patch -Np1 -i "$PKGLUADIR/patches/python-posix-2024.patch"
		# OpenSSL 4 support (upstream commit 3364e7e6, gh-146207); Zoidberg
		# ships OpenSSL 4, and 3.14 does not build against it without this.
		patch -Np1 -i "$PKGLUADIR/patches/python-openssl-4.patch"

		# Zoidberg ships no Tcl/Tk: never build tkinter, even if the build
		# host has Tk installed.
		printf '*disabled*\n_tkinter\n' > Modules/Setup.local
	]],
		opts
	)
end

function build()
	-- --enable-optimizations (PGO) is not used: the profiling run of the
	-- test suite makes the build several times slower in CI.
	cmd(
		[[
		cd "Python-$VER"
		./configure --prefix=/usr \
			--enable-shared \
			--with-computed-gotos \
			--with-lto \
			--enable-ipv6 \
			--with-system-expat \
			--with-dbmliborder=gdbm:ndbm \
			--with-system-libmpdec \
			--enable-loadable-sqlite-extensions \
			--without-ensurepip \
			--with-tzpath=/usr/share/zoneinfo
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "Python-$VER"
		make DESTDIR="$ROOT" install

		ln -s python3 "$ROOT/usr/bin/python"
		ln -s python3-config "$ROOT/usr/bin/python-config"
		ln -s pydoc3 "$ROOT/usr/bin/pydoc"
		ln -s "python$PYVER.1" "$ROOT/usr/share/man/man1/python.1"

		# IDLE needs tkinter, which is not built.
		rm -f "$ROOT"/usr/bin/idle*
		rm -rf "$ROOT/usr/lib/python$PYVER/idlelib" "$ROOT/usr/lib/python$PYVER/tkinter"

		install -dm755 "$ROOT/usr/lib/python$PYVER/Tools/i18n" "$ROOT/usr/lib/python$PYVER/Tools/scripts"
		install -m755 Tools/i18n/msgfmt.py Tools/i18n/pygettext.py "$ROOT/usr/lib/python$PYVER/Tools/i18n/"
		install -m755 Tools/scripts/README Tools/scripts/*.py "$ROOT/usr/lib/python$PYVER/Tools/scripts/"

		# PEP 668: system site-packages are managed by Zoi.
		install -Dm644 "$PKGLUADIR/files/EXTERNALLY-MANAGED" -t "$ROOT/usr/lib/python$PYVER/"

		# The regression test suite is not shipped (Arch splits it into
		# python-tests).
		rm -r "$ROOT/usr/lib/python$PYVER/test"
	]],
		opts
	)
	zlicense("Python-" .. version .. "/LICENSE")
end

function test()
	cmd([[/usr/bin/python3 --version]])
end

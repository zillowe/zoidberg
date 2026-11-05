local version = ZOI.VERSION or "6.6"
local tag = "v" .. string.gsub(version, "%.", "_")
local git_url = "https://github.com/ThomasDickey/ncurses-snapshots.git"

metadata({
	name = "ncurses",
	repo = "core",
	version = version,
	revision = "1",
	description = "System V Release 4.0 curses emulation library",
	website = "https://invisible-island.net/ncurses/ncurses.html",
	license = "MIT-open-group",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Thomas E. Dickey",
		website = "https://invisible-island.net/ncurses/ncurses.html",
	},
	bins = {
		"clear",
		"infocmp",
		"ncursesw6-config",
		"reset",
		"tabs",
		"tic",
		"toe",
		"tput",
		"tset",
	},
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
					"pacman:autoconf-archive",
					"pacman:gcc",
					"pacman:git",
					"pacman:make",
					"pacman:patch",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d ncurses ]; then
			git clone --depth 1 --branch %s %s ncurses
		fi

		cd ncurses
		if [ ! -f .patched ]; then
			patch -Np1 -i "${PKGLUADIR}/ncurses-6.6-libs.patch"
			patch -Np1 -i "${PKGLUADIR}/ncurses-6.6-pkgconfig.patch"
			touch .patched
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd ncurses

		./configure \
			--prefix=/usr \
			--disable-root-access \
			--disable-root-environ \
			--disable-setuid-environ \
			--enable-widec \
			--enable-pc-files \
			--mandir=/usr/share/man \
			--with-cxx-binding \
			--with-cxx-shared \
			--with-manpage-format=normal \
			--with-pkg-config-libdir=/usr/lib/pkgconfig \
			--with-shared \
			--with-versioned-syms \
			--with-xterm-kbs=del \
			--without-ada

		make -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"/usr/{lib/pkgconfig,share/licenses/ncurses}

		make DESTDIR="$ROOT" install -C ncurses
		install -m644 ncurses/COPYING "$ROOT/usr/share/licenses/ncurses/COPYING"

		# Non-wide-character compatibility wrappers
		for lib in ncurses ncurses++ form panel menu; do
			printf "INPUT(-l%%sw)\n" "${lib}" > "$ROOT/usr/lib/lib${lib}.so"
			ln -sf "${lib}w.pc" "$ROOT/usr/lib/pkgconfig/${lib}.pc"
		done

		# Curses compatibility
		printf "INPUT(-lncursesw)\n" > "$ROOT/usr/lib/libcursesw.so"
		ln -sf libncurses.so "$ROOT/usr/lib/libcurses.so"

		# Tic and tinfo compatibility
		_major="%s"
		_major="${_major%%%%.*}"
		for lib in tic tinfo; do
			printf "INPUT(libncursesw.so.%%s)\n" "${_major}" > "$ROOT/usr/lib/lib${lib}.so"
			ln -sf "libncursesw.so.${_major}" "$ROOT/usr/lib/lib${lib}.so.${_major}"
			ln -sf ncursesw.pc "$ROOT/usr/lib/pkgconfig/${lib}.pc"
		done
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/clear -V || /usr/bin/tic -V || true
	]])
end

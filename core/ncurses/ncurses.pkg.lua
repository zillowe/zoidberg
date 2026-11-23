local version = ZOI.VERSION or "6.6"
local sha512 = "02647baae53abc844fbadee5b0a2187ad073125c4e8950df6d1c4feb781cb74ba64fb838cedfee2c246c39932187f6775b1df124f18b99a4233f0d98c72191de"
-- Release signing key (Thomas E. Dickey), as published on invisible-island.net.
local signing_key = "19882D92DDA4C400C22C0D56CC2AF4472167BE03"

metadata({
	name = "ncurses",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "ncurses-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/ncurses" \
				"https://mirrors.kernel.org/gnu/ncurses" \
				"https://invisible-mirror.net/archives/ncurses"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "ncurses-$VER.tar.gz"
		fetch "ncurses-$VER.tar.gz.sig"
		echo "$SHA512  ncurses-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "ncurses-$VER.tar.gz"
		cd "ncurses-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/ncurses-6.6-libs.patch"
		patch -Np1 -i "$PKGLUADIR/patches/ncurses-6.6-pkgconfig.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "ncurses-$VER"

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
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/usr/lib/pkgconfig

		make DESTDIR="$ROOT" install -C "ncurses-$VER"

		# Non-wide-character compatibility wrappers
		for lib in ncurses ncurses++ form panel menu; do
			printf "INPUT(-l%sw)\n" "${lib}" > "$ROOT/usr/lib/lib${lib}.so"
			ln -sf "${lib}w.pc" "$ROOT/usr/lib/pkgconfig/${lib}.pc"
		done

		# Curses compatibility
		printf "INPUT(-lncursesw)\n" > "$ROOT/usr/lib/libcursesw.so"
		ln -sf libncurses.so "$ROOT/usr/lib/libcurses.so"

		# Tic and tinfo compatibility
		_major="${VER%%.*}"
		for lib in tic tinfo; do
			printf "INPUT(libncursesw.so.%s)\n" "${_major}" > "$ROOT/usr/lib/lib${lib}.so"
			ln -sf "libncursesw.so.${_major}" "$ROOT/usr/lib/lib${lib}.so.${_major}"
			ln -sf ncursesw.pc "$ROOT/usr/lib/pkgconfig/${lib}.pc"
		done
	]],
		opts
	)

	zlicense("ncurses-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/clear -V || /usr/bin/tic -V || true
	]])
end

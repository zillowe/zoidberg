local version = ZOI.VERSION or "3.8.2"
local sha512 =
	"d4d23af6671406e97257892f90651b67f2ab95219831372be032190b7156c10a3435d457857e677445df8b2327aacccc15344acbbc3808a6f332a93cce23b444"
-- Upstream signs releases (key 7DF84374B1EE1F9764BBE25D0DDCAA3278D5264E, Akim Demaille),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "bison",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "The GNU general-purpose parser generator",
	website = "https://www.gnu.org/software/bison/bison.html",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "bison", "yacc" },
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
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:m4",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/gettext",
			"zoi:@core/glibc",
			"zoi:@core/m4",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/bison" \
				"https://mirrors.kernel.org/gnu/bison" \
				"https://ftp.gnu.org/gnu/bison"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "bison-$VER.tar.xz"
		echo "$SHA512  bison-$VER.tar.xz" | sha512sum -c -
		tar -xf "bison-$VER.tar.xz"
		cd "bison-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/glr2.patch"
	]],
		opts
	)
end

function build()
	-- bison 3.8.2's bundled gnulib predates glibc declaring
	-- posix_spawn_file_actions_addchdir (as a redirect to the _np symbol), so
	-- its link test fails and gnulib re-declares the function with a
	-- conflicting type. Tell configure what glibc actually provides.
	cmd(
		[[
		cd "bison-$VER"
		ac_cv_func_posix_spawn_file_actions_addchdir=yes \
		gl_cv_func_posix_spawn_works=yes \
		CFLAGS="${CFLAGS:-} -ffat-lto-objects" \
		./configure \
			--prefix=/usr \
			--datadir=/usr/share
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "bison-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("bison-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/bison --version || bison --version
	]])
end

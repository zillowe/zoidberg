local version = ZOI.VERSION or "9.12"
local tar_url = string.format("https://ftp.gnu.org/gnu/coreutils/coreutils-%s.tar.gz", version)

metadata({
	name = "coreutils",
	repo = "core",
	version = version,
	revision = "1",
	description = "The basic file, shell and text manipulation utilities of the GNU operating system",
	website = "https://www.gnu.org/software/coreutils/",
	license = "GPL-3.0-or-later AND GFDL-1.3-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.gnu.org/software/coreutils/",
	},
	bins = {
		"b2sum",
		"base32",
		"base64",
		"basename",
		"basenc",
		"cat",
		"chcon",
		"chgrp",
		"chmod",
		"chown",
		"chroot",
		"cksum",
		"comm",
		"cp",
		"csplit",
		"cut",
		"date",
		"dd",
		"df",
		"dir",
		"dircolors",
		"dirname",
		"du",
		"echo",
		"env",
		"expand",
		"expr",
		"factor",
		"false",
		"fmt",
		"fold",
		"groups",
		"head",
		"hostid",
		"id",
		"install",
		"join",
		"link",
		"ln",
		"logname",
		"ls",
		"md5sum",
		"mkdir",
		"mkfifo",
		"mknod",
		"mktemp",
		"mv",
		"nice",
		"nl",
		"nohup",
		"nproc",
		"numfmt",
		"od",
		"paste",
		"pathchk",
		"pinky",
		"pr",
		"printenv",
		"printf",
		"ptx",
		"pwd",
		"readlink",
		"realpath",
		"rm",
		"rmdir",
		"runcon",
		"seq",
		"sha1sum",
		"sha224sum",
		"sha256sum",
		"sha384sum",
		"sha512sum",
		"shred",
		"shuf",
		"sleep",
		"sort",
		"split",
		"stat",
		"stdbuf",
		"stty",
		"sync",
		"tac",
		"tail",
		"tee",
		"test",
		"timeout",
		"touch",
		"tr",
		"true",
		"truncate",
		"tsort",
		"tty",
		"uname",
		"unexpand",
		"uniq",
		"unlink",
		"users",
		"vdir",
		"wc",
		"who",
		"whoami",
		"yes",
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
					"pacman:acl",
					"pacman:attr",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:gmp",
					"pacman:gperf",
					"pacman:libcap",
					"pacman:make",
					"pacman:openssl",
					"pacman:patch",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "coreutils-%s" ]; then
			if ! curl -sSfL "%s" -o "coreutils-%s.tar.gz"; then
				echo "Tarball download failed, falling back to git clone..."
				git clone --depth 1 --branch "v%s" https://git.savannah.gnu.org/git/coreutils.git "coreutils-%s"
				cd "coreutils-%s"
				git clone --depth 1 https://git.savannah.gnu.org/git/gnulib.git gnulib
				export GNULIB_SRCDIR="$(pwd)/gnulib"
				./bootstrap --skip-po --gnulib-srcdir="$(pwd)/gnulib"
				cd ..
			else
				tar -xf "coreutils-%s.tar.gz"
			fi
		fi

		cd "coreutils-%s"
		if [ ! -f .patched ]; then
			patch -Np1 -i "${PKGLUADIR}/0001-env-printenv-only-quote-when-outputting-to-terminals.patch" || true
			touch .patched
		fi
	]],
		version,
		tar_url,
		version,
		version,
		version,
		version,
		version,
		version
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "coreutils-%s"

		export FORCE_UNSAFE_CONFIGURE=1
		touch -c aclocal.m4 configure Makefile.in

		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--with-openssl \
			--enable-no-install-program=kill,uptime

		make -j"$(nproc)"
	]],
		version
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"

		make -C "coreutils-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/ls --version || ls --version
	]])
end

local version = ZOI.VERSION or "9.12"
local sha512 =
	"f25514cf02fd25365252d9a8f6fc5f8ed063fffdcb11c7eff380e3fa632741105d11b45ded332a2af5e913f77a143b68a2bd1fbdca0085e127fb17c80c35279b"
-- Release signing key (Pádraig Brady), listed in the GNU keyring.
local signing_key = "6C37DC12121A5006BC1DB804DF6FD971306037D9"

metadata({
	name = "coreutils",
	repo = "core",
	version = version,
	revision = "8",
	debug = { sub_package = true },
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
					"pacman:libcap",
					"pacman:make",
					"pacman:openssl",
					"pacman:patch",
					"pacman:tar",
					"pacman:texinfo",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/acl",
			"zoi:@core/attr",
			"zoi:@core/glibc",
			"zoi:@core/gmp",
			"zoi:@core/libcap",
			"zoi:@core/openssl",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "coreutils-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/coreutils" \
				"https://mirrors.kernel.org/gnu/coreutils" \
				"https://ftp.gnu.org/gnu/coreutils"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "coreutils-$VER.tar.xz"
		fetch "coreutils-$VER.tar.xz.sig"
		echo "$SHA512  coreutils-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "coreutils-$VER.tar.xz"
		cd "coreutils-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/0001-env-printenv-only-quote-when-outputting-to-terminals.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "coreutils-$VER"
		export FORCE_UNSAFE_CONFIGURE=1
		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--with-openssl \
			--enable-no-install-program=kill,uptime
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "coreutils-$VER" DESTDIR="$ROOT" install
		# The Info index is generated on the target, never shipped.
		rm -f "$ROOT/usr/share/info/dir"
	]],
		opts
	)

	zlicense("coreutils-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/ls --version || ls --version
	]])
end

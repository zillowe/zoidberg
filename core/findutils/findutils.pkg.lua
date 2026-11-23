local version = ZOI.VERSION or "4.11.0"
local sha512 = "1b667c5363b599135ceabab6b4b5388dbee6de4e7fa301f5dfefc854473e442fbfe7dda93a28a70505c026987acd375d13169f76d18da49d29c1fb2e09c83fef"
-- Upstream signs releases (key 0CF4E8D871593224842832B888DD9E08C5DDACB9, James Youngman),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "findutils",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "GNU utilities to locate files (find, xargs)",
	website = "https://www.gnu.org/software/findutils/",
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
	bins = { "find", "xargs" },
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
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:make",
					"pacman:sed",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/findutils" \
				"https://mirrors.kernel.org/gnu/findutils" \
				"https://ftp.gnu.org/gnu/findutils"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "findutils-$VER.tar.xz"
		echo "$SHA512  findutils-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	cmd(
		[[
		tar -xf "findutils-$VER.tar.xz"
		cd "findutils-$VER"
		# Don't build or install locate (mlocate/plocate provide a secure one).
		sed -e '/^SUBDIRS/s/locate//' -e 's/frcode locate updatedb//' -i Makefile.in
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "findutils-$VER"
		./configure --prefix=/usr
		# locate is not built, but the docs want this file from its directory.
		make -C locate dblocation.texi
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "findutils-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("findutils-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/find --version || find --version
		/usr/bin/xargs --version || xargs --version
	]])
end

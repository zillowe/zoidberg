local version = ZOI.VERSION or "1.35"
local sha512 = "8b84ed661e6c878fa33eb5c1808d20351e6f40551ac63f96014fb0d0b9c72d5d94d8865d39e36bcb184fd250f84778a3b271bbd8bd2ceb69eece0c3568577510"
-- Upstream signs releases (key 325F650C4C2B6AD58807327A3602B07F55D0C732, Sergey Poznyakoff),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "tar",
	repo = "core",
	version = version,
	revision = "7",
	debug = { sub_package = true },
	description = "Utility used to store, backup, and transport files",
	website = "https://www.gnu.org/software/tar/",
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
	bins = { "tar" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "scripts" },
	main_subs = { "main" },
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
			"zoi:@core/glibc",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/acl",
					"zoi:@core/glibc",
				},
			},
			scripts = {
				required = {
					"zoi:@core/bash",
					"zoi:@core/tar",
				},
			},
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
				"https://ftpmirror.gnu.org/gnu/tar" \
				"https://mirrors.kernel.org/gnu/tar" \
				"https://ftp.gnu.org/gnu/tar"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "tar-$VER.tar.xz"
		echo "$SHA512  tar-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	cmd(
		[[
		tar -xf "tar-$VER.tar.xz"
		cd "tar-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/fix-libacl-conflicts.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "tar-$VER"
		export FORCE_UNSAFE_CONFIGURE=1
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--libexecdir=/usr/lib/tar \
			--enable-backup-scripts
		make -j"$(nproc)" WERROR_CFLAGS=""
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			make -C "tar-$VER" DESTDIR="$ROOT" install
			# The backup/restore scripts belong in tar:scripts.
			rm -f "$ROOT"/usr/bin/{backup,restore}
			rm -f "$ROOT"/usr/lib/tar/{backup.sh,dump-remind}
		]],
			opts
		)
		zlicense("tar-" .. version .. "/COPYING")
	elseif sub == "scripts" then
		cmd(
			[[
			cd "tar-$VER"
			install -Dm755 scripts/backup "$ROOT/usr/bin/backup"
			install -Dm755 scripts/restore "$ROOT/usr/bin/restore"
			install -Dm755 scripts/backup.sh "$ROOT/usr/lib/tar/backup.sh"
			install -Dm755 scripts/dump-remind "$ROOT/usr/lib/tar/dump-remind"
		]],
			opts
		)
		zlicense("tar-" .. version .. "/COPYING")
	end
end

function test()
	cmd([[
		/usr/bin/tar --version || tar --version
	]])
end

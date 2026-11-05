local version = ZOI.VERSION or "1.35"
local tar_url = string.format("https://ftp.gnu.org/gnu/tar/tar-%s.tar.gz", version)

metadata({
	name = "tar",
	repo = "core",
	version = version,
	revision = "2",
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
					"pacman:autoconf",
					"pacman:automake",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "tar-%s" ]; then
			if ! curl -sSfL "%s" -o "tar-%s.tar.gz"; then
				echo "Tarball download failed, falling back to git clone..."
				git clone --depth 1 --branch "v%s" https://git.savannah.gnu.org/git/tar.git "tar-%s"
				cd "tar-%s"
				git clone --depth 1 https://git.savannah.gnu.org/git/gnulib.git gnulib
				git clone --depth 1 https://git.savannah.gnu.org/git/paxutils.git paxutils
				export GNULIB_SRCDIR="$(pwd)/gnulib"
				./bootstrap --skip-po
				cd ..
			else
				tar -xf "tar-%s.tar.gz"
			fi
		fi

		cd "tar-%s"
		if [ ! -f .patched ]; then
			patch -Np1 -i "${PKGLUADIR}/fix-libacl-conflicts.patch" || true
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
		cd "tar-%s"

		export FORCE_UNSAFE_CONFIGURE=1
		find . -type f \( -name "config.hin" -o -name "configh.in" -o -name "config.h.in" -o -name "Makefile.in" -o -name "aclocal.m4" -o -name "configure" \) -exec touch -c {} +

		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--libexecdir=/usr/lib/tar \
			--enable-backup-scripts

		make -j"$(nproc)" WERROR_CFLAGS=""
	]],
		version
	))
end

function package(args)
	local sub = (args and args.sub) or "main"
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	if sub == "main" or sub == "" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"

			make -C "tar-%s" DESTDIR="$ROOT" install
			# Remove backup/restore scripts which belong in tar:scripts
			rm -f "$ROOT"/usr/bin/{backup,restore}
			rm -f "$ROOT"/usr/lib/tar/{backup.sh,dump-remind}
		]],
			root,
			version
		))
	elseif sub == "scripts" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/lib/tar

			cd "tar-%s"
			install -m755 scripts/backup "$ROOT/usr/bin/backup" 2>/dev/null || true
			install -m755 scripts/restore "$ROOT/usr/bin/restore" 2>/dev/null || true
			install -m755 scripts/backup.sh "$ROOT/usr/lib/tar/backup.sh" 2>/dev/null || true
			install -m755 scripts/dump-remind "$ROOT/usr/lib/tar/dump-remind" 2>/dev/null || true
		]],
			root,
			version
		))
	end

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/tar --version || tar --version
	]])
end

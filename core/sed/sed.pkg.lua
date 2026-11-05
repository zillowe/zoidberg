local version = ZOI.VERSION or "4.10"
local tar_url = string.format("https://ftp.gnu.org/gnu/sed/sed-%s.tar.gz", version)

metadata({
	name = "sed",
	repo = "core",
	version = version,
	revision = "2",
	description = "GNU stream editor",
	website = "https://www.gnu.org/software/sed/",
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
	bins = { "sed" },
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:make",
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
		if [ ! -d "sed-%s" ]; then
			if ! curl -sSfL "%s" -o "sed-%s.tar.gz"; then
				echo "Tarball download failed, falling back to git clone..."
				git clone --depth 1 --branch "v%s" https://git.savannah.gnu.org/git/sed.git "sed-%s"
				cd "sed-%s"
				git clone --depth 1 https://git.savannah.gnu.org/git/gnulib.git gnulib
				export GNULIB_SRCDIR="$(pwd)/gnulib"
				./bootstrap --skip-po --gnulib-srcdir="$(pwd)/gnulib"
				cd ..
			else
				tar -xf "sed-%s.tar.gz"
			fi
		fi
	]],
		version,
		tar_url,
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
		cd "sed-%s"

		find . -type f \( -name "config.hin" -o -name "configh.in" -o -name "config.h.in" -o -name "Makefile.in" -o -name "aclocal.m4" -o -name "configure" \) -exec touch -c {} +

		./configure \
			--prefix=/usr

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

		make -C "sed-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/sed --version || sed --version
	]])
end

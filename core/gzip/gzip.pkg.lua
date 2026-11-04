local version = ZOI.VERSION or "1.15"
local tar_url = string.format("https://ftp.gnu.org/pub/gnu/gzip/gzip-%s.tar.xz", version)

metadata({
	name = "gzip",
	repo = "core",
	version = version,
	revision = "3",
	description = "GNU compression utility",
	website = "https://www.gnu.org/software/gzip/",
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
	bins = {
		"gunzip",
		"gzexe",
		"gzip",
		"uncompress",
		"zcat",
		"zcmp",
		"zdiff",
		"zegrep",
		"zfgrep",
		"zforce",
		"zgrep",
		"zless",
		"zmore",
		"znew",
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
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
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
		if [ ! -d "gzip-%s" ]; then
			if ! curl -sSfL "%s" -o "gzip-%s.tar.xz"; then
				echo "Tarball download failed, falling back to git clone..."
				git clone --depth 1 --branch "v%s" https://git.savannah.gnu.org/git/gzip.git "gzip-%s"
				cd "gzip-%s"
				git clone --depth 1 https://git.savannah.gnu.org/git/gnulib.git gnulib
				export GNULIB_SRCDIR="$(pwd)/gnulib"
				./bootstrap --gnulib-srcdir="$(pwd)/gnulib"
				cd ..
			else
				tar -xf "gzip-%s.tar.xz"
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
		cd "gzip-%s"

		./configure \
			--prefix=/usr \
			--disable-gcc-warnings

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

		make -C "gzip-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/gzip --version || gzip --version
	]])
end

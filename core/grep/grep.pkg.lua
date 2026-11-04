local version = ZOI.VERSION or "3.12"
local tar_url = string.format("https://ftp.gnu.org/gnu/grep/grep-%s.tar.gz", version)

metadata({
	name = "grep",
	repo = "core",
	version = version,
	revision = "3",
	description = "A string search utility",
	website = "https://www.gnu.org/software/grep/",
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
	bins = { "grep", "egrep", "fgrep" },
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
					"pacman:pcre2",
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
		if [ ! -d "grep-%s" ]; then
			if ! curl -sSfL "%s" -o "grep-%s.tar.gz"; then
				echo "Tarball download failed, falling back to git clone..."
				git clone --depth 1 --branch "v%s" https://git.savannah.gnu.org/git/grep.git "grep-%s"
				cd "grep-%s"
				git clone --depth 1 https://git.savannah.gnu.org/git/gnulib.git gnulib
				export GNULIB_SRCDIR="$(pwd)/gnulib"
				./bootstrap --skip-po --gnulib-srcdir="$(pwd)/gnulib"
				cd ..
			else
				tar -xf "grep-%s.tar.gz"
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
		cd "grep-%s"

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

		make -C "grep-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/grep --version || grep --version
	]])
end

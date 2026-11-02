local version = ZOI.VERSION or "4.11.0"
local tar_url = string.format("https://ftp.gnu.org/pub/gnu/findutils/findutils-%s.tar.xz", version)

metadata({
	name = "findutils",
	repo = "core",
	version = version,
	revision = "1",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "findutils-%s" ]; then
			if ! curl -sSfL "%s" -o "findutils-%s.tar.xz"; then
				echo "Tarball download failed, falling back to git clone..."
				git clone --depth 1 --branch "v%s" https://git.savannah.gnu.org/git/findutils.git "findutils-%s"
				cd "findutils-%s"
				git clone --depth 1 https://git.savannah.gnu.org/git/gnulib.git gnulib
				export GNULIB_SRCDIR="$(pwd)/gnulib"
				./bootstrap --gnulib-srcdir="$(pwd)/gnulib"
				cd ..
			else
				tar -xf "findutils-%s.tar.xz"
			fi
		fi

		cd "findutils-%s"
		sed -e '/^SUBDIRS/s/locate//' -e 's/frcode locate updatedb//' -i Makefile.in 2>/dev/null || true
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
		cd "findutils-%s"

		./configure --prefix=/usr
		make -C locate dblocation.texi 2>/dev/null || true
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

		make -C "findutils-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/find --version || find --version
		/usr/bin/xargs --version || xargs --version
	]])
end

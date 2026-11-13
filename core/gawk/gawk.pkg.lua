local version = ZOI.VERSION or "5.4.1"
local tar_url = string.format("https://ftp.gnu.org/pub/gnu/gawk/gawk-%s.tar.gz", version)

metadata({
	name = "gawk",
	repo = "core",
	version = version,
	revision = "3",
	debug = { sub_package = true },
	description = "GNU version of awk",
	website = "https://www.gnu.org/software/gawk/",
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
	bins = { "gawk", "awk" },
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:make",
					"pacman:mpfr",
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
		if [ ! -d "gawk-%s" ]; then
			if ! curl -sSfL "%s" -o "gawk-%s.tar.gz"; then
				echo "Tarball download failed, falling back to git clone..."
				git clone --depth 1 --branch "gawk-%s" https://git.savannah.gnu.org/git/gawk.git "gawk-%s"
			else
				tar -xf "gawk-%s.tar.gz"
			fi
		fi
	]],
		version,
		tar_url,
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
		cd "gawk-%s"

		find . -type f \( -name "config.hin" -o -name "configh.in" -o -name "config.h.in" -o -name "Makefile.in" -o -name "aclocal.m4" -o -name "configure" \) -exec touch -c {} +

		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--sysconfdir=/etc \
			--without-libsigsegv

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

		make -C "gawk-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/gawk --version || gawk --version
	]])
end

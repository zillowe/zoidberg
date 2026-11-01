local version = ZOI.VERSION or "5.8.4"
local tag = "v" .. version
local git_url = "https://github.com/tukaani-project/xz.git"

metadata({
	name = "xz",
	repo = "core",
	version = version,
	revision = "1",
	description = "Library and command line tools for XZ and LZMA compressed files",
	website = "https://tukaani.org/xz/",
	license = "GPL-2.0-or-later AND 0BSD AND LicenseRef-Public-Domain AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Lasse Collin and others",
		website = "https://tukaani.org/xz/",
	},
	bins = {
		"xz",
		"unxz",
		"xzcat",
		"lzma",
		"unlzma",
		"lzcat",
		"xzdec",
		"lzmadec",
		"xzdiff",
		"lzdiff",
		"xzcmp",
		"lzcmp",
		"xzgrep",
		"lzgrep",
		"xzegrep",
		"lzegrep",
		"xzfgrep",
		"lzfgrep",
		"xzless",
		"lzless",
		"xzmore",
		"lzmore",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux" },
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
					"pacman:diffutils",
					"pacman:doxygen",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:libtool",
					"pacman:make",
					"pacman:po4a",
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
		if [ ! -d xz ]; then
			git clone --depth 1 --branch %s %s xz
		fi
		cd xz
		./autogen.sh
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd xz

		./configure \
			--prefix=/usr \
			--disable-rpath \
			--enable-doxygen \
			--disable-werror

		make -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"

		make -C xz DESTDIR="$ROOT" install

		mkdir -p "$ROOT/usr/share/licenses/xz"
		for file in "$ROOT"/usr/share/doc/xz/COPYING*; do
			[ -f "$file" ] && ln -sf "/usr/share/doc/xz/$(basename "$file")" "$ROOT/usr/share/licenses/xz/"
		done
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/xz --version || xz --version
	]])
end

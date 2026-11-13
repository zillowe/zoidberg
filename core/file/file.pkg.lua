local version = ZOI.VERSION or "5.48"
local tag = "FILE" .. string.gsub(version, "%.", "_")
local git_url = "https://github.com/file/file.git"

metadata({
	name = "file",
	repo = "core",
	version = version,
	revision = "3",
	debug = { sub_package = true },
	description = "File type identification utility",
	website = "https://www.darwinsys.com/file/",
	license = "BSD-2-Clause-Darwin",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Ian Darwin and Christos Zoulas",
		website = "https://www.darwinsys.com/file/",
	},
	bins = { "file" },
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
					"pacman:bzip2",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:git",
					"pacman:libseccomp",
					"pacman:libtool",
					"pacman:make",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bzip2",
			"zoi:@core/glibc",
			"zoi:@core/xz",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d file ]; then
			git clone --depth 1 --branch %s %s file
		fi

		cd file
		autoreconf -fiv
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd file

		export CFLAGS="${CFLAGS} -pthread"
		./configure \
			--prefix=/usr \
			--datadir=/usr/share/file \
			--enable-fsect-man5 \
			--enable-libseccomp

		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool 2>/dev/null || true
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

		make -C file DESTDIR="$ROOT" install
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/file --version || file --version
	]])
end

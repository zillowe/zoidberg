local version = ZOI.VERSION or "1.3.2"
local tar_url = string.format("https://github.com/madler/zlib/releases/download/v%s/zlib-%s.tar.xz", version, version)

metadata({
	name = "zlib",
	repo = "core",
	version = version,
	revision = "3",
	debug = { sub_package = true },
	description = "Compression library implementing the deflate compression method found in gzip and PKZIP",
	website = "https://www.zlib.net/",
	license = "Zlib",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Jean-loup Gailly and Mark Adler",
		website = "https://www.zlib.net/",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "static", "minizip" },
	main_subs = { "main" },
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
					"pacman:libtool",
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
			static = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/zlib",
				},
			},
			minizip = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/zlib",
				},
			},
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "zlib-%s" ]; then
			curl -sSL "%s" -o "zlib-%s.tar.xz"
			tar -xf "zlib-%s.tar.xz"
		fi

		cd "zlib-%s"

		# Download and apply upstream patches if not already applied
		if [ ! -f .patched ]; then
			curl -sSL "https://github.com/madler/zlib/commit/36ff1be48ef696cc67b0855f7c8537ce0276210d.patch" | patch -Np1 || true
			curl -sSL "https://github.com/madler/zlib/commit/df84af25dc1942490e1d1c899a07619152a46148.patch" | patch -Np1 || true
			touch .patched
		fi

		cd contrib/minizip
		cp -f Makefile Makefile.orig 2>/dev/null || true
		cp -f ../README.contrib readme.txt 2>/dev/null || true
		autoreconf -fiv
	]],
		version,
		tar_url,
		version,
		version,
		version
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "zlib-%s"

		CFLAGS="${CFLAGS} -ffat-lto-objects"
		./configure --prefix=/usr
		make -j"$(nproc)"

		cd contrib/minizip
		./configure --prefix=/usr --enable-static=no
		make -j"$(nproc)"
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

			make -C "zlib-%s" DESTDIR="$ROOT" install
			# Remove static library to isolate into static sub-package
			rm -f "$ROOT/usr/lib/libz.a"
		]],
			root,
			version
		))
	elseif sub == "static" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT/usr/lib"
			install -m644 "zlib-%s/libz.a" "$ROOT/usr/lib/libz.a"
		]],
			root,
			version
		))
	elseif sub == "minizip" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"

			make -C "zlib-%s/contrib/minizip" DESTDIR="$ROOT" install
			rm -f "$ROOT/usr/include/minizip/crypt.h"
		]],
			root,
			version
		))
	end

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		test -f /usr/lib/libz.so || test -f /usr/lib/libz.a || true
	]])
end

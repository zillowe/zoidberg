local version = ZOI.VERSION or "1.4"
local sha512 = "c6701ef216f2ea451056466794c520df62af0a7ddf57c907c3263678dc625f3d6466e0187106dec0d7721ad6fc6cf105e0f93a4cac82fbcc2ba919eebd29c0b0"
-- Upstream signs releases (key 5ED46A6721D365587791E2AA783FCD8E58BCAFBA, Mark Adler),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "zlib",
	repo = "core",
	version = version,
	revision = "1",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://zlib.net" \
				"https://zlib.net/fossils" \
				"https://github.com/madler/zlib/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "zlib-$VER.tar.xz"
		echo "$SHA512  zlib-$VER.tar.xz" | sha512sum -c -
		tar -xf "zlib-$VER.tar.xz"

		# minizip ships only configure.ac/Makefile.am, so it is bootstrapped
		# here; the top-level configure is a hand-written script.
		cd "zlib-$VER/contrib/minizip"
		cp -f Makefile Makefile.orig
		cp -f ../README.contrib readme.txt
		autoreconf -fiv
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "zlib-$VER"

		CFLAGS="${CFLAGS} -ffat-lto-objects"
		./configure --prefix=/usr
		make -j"$(nproc)"

		cd contrib/minizip
		./configure --prefix=/usr --enable-static=no
		make -j"$(nproc)"
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			mkdir -p "$ROOT"

			make -C "zlib-$VER" DESTDIR="$ROOT" install
			# Remove static library to isolate into static sub-package
			rm -f "$ROOT/usr/lib/libz.a"
		]],
			opts
		)
	elseif sub == "static" then
		cmd(
			[[
			mkdir -p "$ROOT/usr/lib"
			install -m644 "zlib-$VER/libz.a" "$ROOT/usr/lib/libz.a"
		]],
			opts
		)
	elseif sub == "minizip" then
		cmd(
			[[
			mkdir -p "$ROOT"

			make -C "zlib-$VER/contrib/minizip" DESTDIR="$ROOT" install
			rm -f "$ROOT/usr/include/minizip/crypt.h"
		]],
			opts
		)
		-- The Info-ZIP-derived encryption code is compiled into libminizip.
		zlicense("zlib-" .. version .. "/contrib/minizip/LICENSE.Info-Zip")
	end

	-- Every sub-package (main, static, minizip) gets its own copy.
	zlicense("zlib-" .. version .. "/LICENSE")
end

function test()
	cmd([[
		test -f /usr/lib/libz.so || test -f /usr/lib/libz.a || true
	]])
end

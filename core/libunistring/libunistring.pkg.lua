local version = ZOI.VERSION or "1.5"
local sha512 = "cbf6a1ddb8dbdd922d7650c110adef285133c303e69e943fbe240bc988954912f0fc7fbd205feacb3f6b98bda53df07ee2ad4e9ec241b8e78d0c52083a9f5c32"
-- Release signing key (Bruno Haible), from upstream's published keys.
local signing_key = "E0FFBD975397F77A32AB76ECB6301D9E1BBEAC08"

metadata({
	name = "libunistring",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Library for manipulating Unicode strings and C strings",
	website = "https://www.gnu.org/software/libunistring/",
	license = "LGPL-3.0-or-later OR GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
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
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libunistring-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/libunistring" \
				"https://mirrors.kernel.org/gnu/libunistring" \
				"https://ftp.gnu.org/gnu/libunistring"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libunistring-$VER.tar.xz"
		fetch "libunistring-$VER.tar.xz.sig"
		echo "$SHA512  libunistring-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libunistring-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "libunistring-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libunistring-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "libunistring-" .. version
	zlicense(src .. "/COPYING")
	zlicense(src .. "/COPYING.LIB")
end

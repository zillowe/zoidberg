local version = ZOI.VERSION or "0.23.3"
local sha512 = "536abf5c713e879daf49a78813d39637c78de1cebb93be841adc0a733fc3fd708dad03acac4a5cf8d3bfd06ab2b6bf3e9b0cb7881367de1c471c4c49dab28465"
-- Release signing key (Tim Rühsen), from upstream's published keys.
local signing_key = "1CB27DBC98614B2D5841646D08302DB6A2670428"

metadata({
	name = "libpsl",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Public Suffix List library",
	website = "https://github.com/rockdaboot/libpsl",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Tim Rühsen",
		website = "https://github.com/rockdaboot",
	},
	bins = { "psl" },
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
					"pacman:libidn2",
					"pacman:libunistring",
					"pacman:make",
					"pacman:python",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libidn2",
			"zoi:@core/libunistring",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libpsl-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/rockdaboot/libpsl/releases/download/$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libpsl-$VER.tar.gz"
		fetch "libpsl-$VER.tar.gz.sig"
		echo "$SHA512  libpsl-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libpsl-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "libpsl-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--disable-gtk-doc \
			--enable-builtin \
			--enable-runtime=libidn2
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libpsl-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "libpsl-" .. version
	zlicense(src .. "/COPYING")
end

local version = ZOI.VERSION or "1.5.8"
local sha512 = "0ae94df4bd508f0e664fa5430687d64904c60d69d9565c18cacb70251f8653cb7c571325d1406c859fdd149048adce8c4b3bf028573064496d7da3436e27b9b0"
-- Release signing key (Colin Watson), from upstream's published keys.
local signing_key = "AC0A4FF12611B6FCCF01C111393587D97D86500B"

metadata({
	name = "libpipeline",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "A C library for manipulating pipelines of subprocesses",
	website = "https://libpipeline.nongnu.org/",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Colin Watson",
		website = "https://libpipeline.nongnu.org/",
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
	local tarball = "libpipeline-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://download.savannah.nongnu.org/releases/libpipeline" \
				"https://download-mirror.savannah.gnu.org/releases/libpipeline"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libpipeline-$VER.tar.gz"
		fetch "libpipeline-$VER.tar.gz.asc"
		echo "$SHA512  libpipeline-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libpipeline-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "libpipeline-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libpipeline-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "libpipeline-" .. version
	zlicense(src .. "/COPYING")
end

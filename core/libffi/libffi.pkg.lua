local version = ZOI.VERSION or "3.8.1"
local sha512 = "44370f8779765ac83161d927025c8178919ae30feffaad6cdd2b9f95fd8314ca96d2c75d23d102f4af06e55787ec25ebf3cf35cec6ea6881c16e526b27bec0dc"
-- Upstream publishes release tarballs without signatures; the hash below
-- matches the SHA-256 GitHub records for the release asset.

metadata({
	name = "libffi",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Portable foreign function interface library",
	website = "https://sourceware.org/libffi/",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Anthony Green",
		website = "https://sourceware.org/libffi/",
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
	local tarball = "libffi-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/libffi/libffi/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libffi-$VER.tar.gz"
		echo "$SHA512  libffi-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "libffi-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "libffi-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--disable-multi-os-directory \
			--disable-exec-static-tramp \
			--enable-pax_emutramp
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libffi-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "libffi-" .. version
	zlicense(src .. "/LICENSE")
	zdoc(src .. "/README.md")
end

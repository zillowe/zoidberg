local version = ZOI.VERSION or "1.8.0"
local sha512 = "1557a835610ceeb01cf84f0eed009061a45a1277f4256f89cd82150eceddbecad0afa35c6959f4d71c9dab2d33044407fd37e482cc8da9b45e5460fa1beac028"
-- Upstream publishes no release tarball or signature; this is GitHub's
-- archive of the v1.8.0 tag, pinned by hash.

metadata({
	name = "libbpf",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Library for loading eBPF programs and reading and manipulating eBPF objects from user-space",
	website = "https://github.com/libbpf/libbpf",
	license = "LGPL-2.1-only OR BSD-2-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "libbpf contributors",
		website = "https://github.com/libbpf/libbpf",
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
					"pacman:libelf",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/elfutils:libelf",
			"zoi:@core/glibc",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libbpf-" .. version .. ".tar.gz"
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors "https://github.com/libbpf/libbpf/archive/refs/tags/v$VER.tar.gz" -o "libbpf-$VER.tar.gz"
		echo "$SHA512  libbpf-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "libbpf-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "libbpf-$VER"
		make -C src -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libbpf-$VER"
		make -C src DESTDIR="$ROOT" LIBSUBDIR=lib install
	]],
		opts
	)

	local src = "libbpf-" .. version
	zlicense(src .. "/LICENSE")
	zlicense(src .. "/LICENSE.BSD-2-Clause")
	zlicense(src .. "/LICENSE.LGPL-2.1-only")
	zdoc(src .. "/README.md")
end

local version = ZOI.VERSION or "1.32"
local sha512 = "7ec0354b3c7062c038d6105f215d447d605cf39cc2573e293dd91a37bbc518da4d7a8af4fe988a44b1884e52d8deed04fac23c4f30eb4a58f325ae789faa5ce5"
-- Upstream signs the uncompressed tarball (dwarves-<v>.tar.sign) with subkey
-- 761A221472D74E7D7DAA1E11B23CA2E9A4227E27 of Arnaldo Carvalho de Melo's key
-- 2DBF5BAA46FB4DED338A335BD65016F35352AA40 (Arch Linux's validpgpkeys), but
-- that subkey is only bound with SHA-1 signatures, which Zoi's verifier
-- rejects. The signature was checked with gpg when this hash was recorded
-- (and it matches Gentoo's); the pinned hash is the trust anchor.

metadata({
	name = "pahole",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Type info tools (pahole, dwarves)",
	website = "https://git.kernel.org/pub/scm/devel/pahole/pahole.git",
	license = "GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Arnaldo Carvalho de Melo and others",
		website = "https://git.kernel.org/pub/scm/devel/pahole/pahole.git",
	},
	bins = {
		"btfdiff",
		"codiff",
		"ctracer",
		"dtagnames",
		"fullcircle",
		"pahole",
		"pdwtags",
		"pfunct",
		"pglobal",
		"prefcnt",
		"scncopy",
		"syscse",
	},
	provides = { "dwarves" },
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
					"pacman:cmake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libelf",
					"pacman:ninja",
					"pacman:tar",
					"pacman:xz",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
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
	cmd(
		[[
		fetch() {
			for base in \
				"https://fedorapeople.org/~acme/dwarves"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "dwarves-$VER.tar.xz"
		echo "$SHA512  dwarves-$VER.tar.xz" | sha512sum -c -
		tar -xf "dwarves-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	-- As Arch: the libbpf copy bundled in the release tarball (lib/bpf) is
	-- linked in statically. Arch's ostra-cg split (Python + matplotlib) is
	-- not built: Python is kept out of the configure run so ostra is not
	-- installed, and Arch's patch for its install path is not needed.
	cmd(
		[[
		cmake -S "dwarves-$VER" -B build -G Ninja \
			-DCMAKE_BUILD_TYPE=None \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DLIB_INSTALL_DIR=/usr/lib \
			-DGIT_SUBMODULE=OFF \
			-DLIBBPF_EMBEDDED=ON \
			-DCMAKE_DISABLE_FIND_PACKAGE_Python3=ON
		cmake --build build -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[DESTDIR="$ROOT" cmake --install build]], opts)
	zlicense("dwarves-" .. version .. "/COPYING")
	-- Bundled, statically linked libbpf (LGPL-2.1 OR BSD-2-Clause)
	zlicense("dwarves-" .. version .. "/lib/bpf/LICENSE", "LICENSE.libbpf")
	zlicense("dwarves-" .. version .. "/lib/bpf/LICENSE.BSD-2-Clause", "LICENSE.libbpf.BSD-2-Clause")
	zlicense("dwarves-" .. version .. "/lib/bpf/LICENSE.LGPL-2.1", "LICENSE.libbpf.LGPL-2.1")
	zdoc("dwarves-" .. version .. "/NEWS")
	zdoc("dwarves-" .. version .. "/README")
end

function test()
	cmd([[
		/usr/bin/pahole --version || pahole --version
	]])
end

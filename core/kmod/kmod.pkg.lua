local version = ZOI.VERSION or "34.3"
local sha512 = "3d47d52443d685b35ecd379427b71c7def6253e9c3152229068ef84682348056cb32755e2c5ee1433617f0e3b90ce96c541fe38b2f7415ebe297e46bad5c97b0"
-- Release signing key (Lucas De Marchi), matching Arch Linux's validpgpkeys.
local signing_key = "EAB33C9690013C733916AC839BA2A5A630CBEA53"

metadata({
	name = "kmod",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "Linux kernel module management tools and library (modprobe, lsmod, depmod)",
	website = "https://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git",
	license = "LGPL-2.1-or-later AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Lucas De Marchi and others",
		website = "https://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git",
	},
	bins = {
		"depmod",
		"insmod",
		"kmod",
		"lsmod",
		"modinfo",
		"modprobe",
		"rmmod",
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
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:meson",
					"pacman:ninja",
					"pacman:openssl",
					"pacman:pkgconf",
					"pacman:scdoc",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/openssl",
			"zoi:@core/xz",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "kmod-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.kernel.org/pub/linux/utils/kernel/kmod" \
				"https://mirrors.kernel.org/pub/linux/utils/kernel/kmod"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "kmod-$VER.tar.xz"
		fetch "kmod-$VER.tar.sign"
		echo "$SHA512  kmod-$VER.tar.xz" | sha512sum -c -
		# kernel.org signs the uncompressed tar.
		xz -dk "kmod-$VER.tar.xz"
	]],
		opts
	)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "kmod-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		meson setup "kmod-$VER" build \
			--prefix=/usr \
			--buildtype=release \
			-Dbuild-tests=false \
			-Dmanpages=true \
			-Dopenssl=enabled \
			-Dxz=enabled \
			-Dzlib=enabled \
			-Dzstd=enabled

		meson compile -C build -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/etc/depmod.d "$ROOT"/etc/modprobe.d "$ROOT"/usr/lib/depmod.d "$ROOT"/usr/lib/modprobe.d

		DESTDIR="$ROOT" meson install -C build

		install -m644 "${PKGLUADIR}/files/depmod-search.conf" "$ROOT/usr/lib/depmod.d/search.conf"
	]],
		opts
	)

	zcp("${pkgluadir}/hooks/depmod.hook.yaml", "${pkgstore}/hooks/kmod-depmod.hook.yaml")

	-- libkmod is LGPL-2.1 (COPYING), the tools are GPL-2.0 (tools/COPYING).
	zlicense("kmod-" .. version .. "/COPYING")
	zlicense("kmod-" .. version .. "/tools/COPYING", "COPYING.tools")
end

function test()
	cmd([[
		/usr/bin/kmod --version || kmod --version || true
	]])
end

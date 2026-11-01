local version = ZOI.VERSION or "34.3"
local tag = "v" .. version
local git_url = "https://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git"

metadata({
	name = "kmod",
	repo = "core",
	version = version,
	revision = "1",
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
	platforms = { "linux" },
	types = { "source" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:git",
					"pacman:meson",
					"pacman:ninja",
					"pacman:openssl",
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
			"zoi:@core/xz",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d kmod ]; then
			git clone --depth 1 --branch "%s" "%s" kmod
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e

		meson setup kmod build \
			--prefix=/usr \
			--buildtype=release \
			-Dbuild-tests=false \
			-Dmanpages=true \
			-Dopenssl=enabled \
			-Dxz=enabled \
			-Dzlib=enabled \
			-Dzstd=enabled

		meson compile -C build -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"/etc/depmod.d "$ROOT"/etc/modprobe.d "$ROOT"/usr/lib/depmod.d "$ROOT"/usr/lib/modprobe.d

		DESTDIR="$ROOT" meson install -C build

		install -m644 "${PKGLUADIR}/depmod-search.conf" "$ROOT/usr/lib/depmod.d/search.conf"
	]],
		root
	))

	zcp("${pkgluadir}/hooks/depmod.hook.yaml", "${pkgstore}/hooks/kmod-depmod.hook.yaml")

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/kmod --version || kmod --version || true
	]])
end

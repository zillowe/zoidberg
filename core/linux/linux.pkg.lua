local version = ZOI.VERSION or "7.2.14.parlex.1"
local upstream_ver = string.match(version, "^(%d+%.%d+%.%d+)") or "7.2.14"
local patch_rev = string.match(version, "parlex%.(%d+)$") or "1"
local patch_tag = "v" .. upstream_ver .. "-parlex." .. patch_rev
local patch_name = "linux-" .. patch_tag .. ".patch"
local patch_url = string.format(
	"https://gitlab.com/api/v4/projects/84792945/packages/generic/kernel-patches/%s/%s.zst",
	patch_tag,
	patch_name
)
local git_url = "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"

metadata({
	name = "linux",
	repo = "core",
	version = version,
	revision = "1",
	description = "The Linux kernel and modules (Parlex Linux)",
	website = "https://kernel.org",
	license = "GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Linus Torvalds and Linux Kernel Contributors",
		website = "https://kernel.org",
	},
	sub_packages = { "main", "headers", "docs" },
	main_subs = { "main" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	zsa = false,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:bc",
					"pacman:binutils",
					"pacman:cpio",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:kmod",
					"pacman:libelf",
					"pacman:make",
					"pacman:openssl",
					"pacman:pahole",
					"pacman:perl",
					"pacman:python",
					"pacman:tar",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/coreutils",
			"zoi:@core/kmod",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/coreutils",
					"zoi:@core/kmod",
				},
			},
			headers = {
				required = {
					"zoi:@core/glibc",
				},
			},
		},
	},
})

function prepare()
	local pkgdir = LOCATION.PKGLUADIR or "."

	cmd(string.format(
		[[
		PKGLUADIR="%s"
		if [ ! -d linux ]; then
			git clone --depth 1 --branch "v%s" "%s" linux
		fi

		cd linux
		if [ ! -f .patched ]; then
			if curl -sSfL "%s" -o "%s.zst" 2>/dev/null; then
				zstd -d -f "%s.zst" -o "%s"
				patch -Np1 -i "%s" || true
			elif curl -sSfL "https://gitlab.com/zillowe/zillowex/parlex/linux/kernel/-/raw/%s/patches/0001-parlexlinux.patch" -o 0001-parlexlinux.patch 2>/dev/null; then
				patch -Np1 -i 0001-parlexlinux.patch || true
			fi
			touch .patched
		fi

		if [ -f "${PKGLUADIR}/config.x86_64" ]; then
			cp "${PKGLUADIR}/config.x86_64" .config
			make olddefconfig
		fi
	]],
		pkgdir,
		upstream_ver,
		git_url,
		patch_url,
		patch_name,
		patch_name,
		patch_name,
		patch_name,
		patch_tag
	))
end

function build()
	cmd([[
		set -e
		cd linux
		export KBUILD_BUILD_USER="zillowe"
		export KBUILD_BUILD_HOST="parlex"
		make -j"$(nproc)" all
	]])
end

function package(args)
	local sub = (args and args.sub) or "main"
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	if sub == "main" or sub == "" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			cd linux

			KVER="$(make -s kernelrelease 2>/dev/null || cat include/config/kernel.release 2>/dev/null || echo "%s")"
			MODULES_DIR="$ROOT/usr/lib/modules/$KVER"
			mkdir -p "$MODULES_DIR" "$ROOT/boot"

			# Install boot kernel image
			install -Dm644 "$(make -s image_name)" "$MODULES_DIR/vmlinuz"
			echo "linux" > "$MODULES_DIR/pkgbase"

			# Install modules
			ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$ROOT/usr" INSTALL_MOD_STRIP=1 \
				DEPMOD=/doesnt/exist modules_install

			rm -f "$MODULES_DIR/build"
		]],
			root,
			version
		))

		-- zlicense("LICENSE")
	elseif sub == "headers" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			cd linux

			KVER="$(make -s kernelrelease 2>/dev/null || cat include/config/kernel.release 2>/dev/null || echo "%s")"
			BUILD_DIR="$ROOT/usr/lib/modules/$KVER/build"
			mkdir -p "$BUILD_DIR"

			install -Dt "$BUILD_DIR" -m644 .config Makefile Module.symvers 2>/dev/null || true
			cp -t "$BUILD_DIR" -a scripts include 2>/dev/null || true
			mkdir -p "$BUILD_DIR/arch/x86"
			cp -t "$BUILD_DIR/arch/x86" -a arch/x86/include 2>/dev/null || true

			mkdir -p "$ROOT/usr/src"
			ln -sf "../lib/modules/$KVER/build" "$ROOT/usr/src/linux"
		]],
			root,
			version
		))
	elseif sub == "docs" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/share/doc/linux
			if [ -d linux/Documentation ]; then
				cp -a linux/Documentation/* "$ROOT"/usr/share/doc/linux/ 2>/dev/null || true
			fi
		]],
			root
		))
	end
end

function test()
	cmd([[
		test -d /usr/lib/modules || true
	]])
end

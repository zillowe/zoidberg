local version = ZOI.VERSION or "7.3.5.parlex.1"
local upstream_ver = string.match(version, "^(%d+%.%d+%.%d+)") or "7.3.5"
local base_ver = string.match(upstream_ver, "^(%d+%.%d+)") or "7.3"
local base_sha512 =
	"14b99ea7cc2adc0798a183ac5f3e184587f2496c3b2d1d53b625574389891c69e8be375b5d03875fe859b09ac9314aa15da604087274ba815671135bd6a0e590"
local patch_sha512 =
	"496566da73c3267aca092b4b5d13075844fa8ac3be1ee4b319534826e22410d8b8d373b7cbe84d02b0e187d0de4f821a5727314d913109ceee1dd1fda821e786"
-- Greg Kroah-Hartman signs the kernel.org tarballs
local signing_key = "647F28654894E3BD457199BE38DBBDC86092693E"

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
	ci = {
		tags = {
			["linux-amd64"] = "saas-linux-large-amd64",
			linux = "saas-linux-large-amd64",
		},
	},
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
					"pacman:bison",
					"pacman:cpio",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:file",
					"pacman:flex",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:kmod",
					"pacman:libelf",
					"pacman:make",
					"pacman:openssl",
					"pacman:pahole",
					"pacman:patch",
					"pacman:perl",
					"pacman:python",
					-- CONFIG_RUST (Rust drivers and the DRM panic QR code)
					-- is silently dropped by olddefconfig without these.
					"pacman:rust",
					"pacman:rust-bindgen",
					"pacman:rust-src",
					"pacman:tar",
					"pacman:xxhash",
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
				optional = {
					"zoi:@core/linux-firmware:firmware images needed for some devices",
					"zoi:@core/dracut:to build an initramfs",
				},
			},
			headers = {
				-- What external modules need to build (Arch's list).
				required = {
					"zoi:@core/binutils",
					"zoi:@core/elfutils:libelf",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/glibc",
					"zoi:@core/openssl",
					"zoi:@core/pahole",
					"zoi:@core/xxhash",
					"zoi:@core/zlib",
					"zoi:@core/zstd",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = {
		UPSTREAM = upstream_ver,
		BASE = base_ver,
		BASE_SHA512 = base_sha512,
		PATCH_SHA512 = patch_sha512,
	},
}

-- Build identity, as Arch sets it (timestamp reproducible when
-- SOURCE_DATE_EPOCH is set).
local kbuild_env = [[
	export KBUILD_BUILD_HOST=parlex
	export KBUILD_BUILD_USER=linux
	export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"
	cd "linux-$UPSTREAM"
]]

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/linux/kernel/v${BASE%%.*}.x" \
				"https://mirrors.edge.kernel.org/pub/linux/kernel/v${BASE%%.*}.x" \
				"https://www.kernel.org/pub/linux/kernel/v${BASE%%.*}.x"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "linux-$BASE.tar.xz"
		fetch "linux-$BASE.tar.sign"
		echo "$BASE_SHA512  linux-$BASE.tar.xz" | sha512sum -c -
		if [ "$UPSTREAM" != "$BASE" ]; then
			fetch "patch-$UPSTREAM.xz"
			echo "$PATCH_SHA512  patch-$UPSTREAM.xz" | sha512sum -c -
		fi
		# kernel.org signs the uncompressed tar.
		xz -dk "linux-$BASE.tar.xz"
	]],
		opts
	)
	local tar = "linux-" .. base_ver .. ".tar"
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tar .. ".xz")
	end
	cmd(
		[[
		tar -xf "linux-$BASE.tar"
		rm -f "linux-$BASE.tar"
		if [ "$UPSTREAM" != "$BASE" ]; then
			mv "linux-$BASE" "linux-$UPSTREAM"
			xz -dc "patch-$UPSTREAM.xz" | patch -d "linux-$UPSTREAM" -Np1 -s
		fi
		cd "linux-$UPSTREAM"
		# Arch's linux-v<upstream>-arch1 patch (i915 eDP wake, the
		# unprivileged_userns_clone sysctl) with Parlex's EXTRAVERSION.
		patch -Np1 -i "$PKGLUADIR/patches/0001-parlexlinux.patch"

		# Arch's config.x86_64 with Parlex's LOCALVERSION, hostname and
		# panic QR-code URL.
		cp "$PKGLUADIR/files/config.x86_64" .config
		make olddefconfig
		diff -u "$PKGLUADIR/files/config.x86_64" .config || :
		make -s kernelrelease > version
		echo "Prepared linux version $(cat version)"
	]],
		opts
	)
end

function build()
	cmd(kbuild_env .. [[
		make -j"$(nproc)" all
		make -C tools/bpf/bpftool vmlinux.h feature-clang-bpf-co-re=1
	]], opts)
end

function package(args)
	local sub = (args and args.sub) or "main"

	-- Every sub-package carries the kernel's license: COPYING plus the
	-- SPDX license texts it refers to (LICENSES/).
	local src = "linux-" .. upstream_ver
	zlicense(src .. "/COPYING")
	zlicense(src .. "/LICENSES")

	if sub == "main" or sub == "" then
		cmd(kbuild_env .. [[
			MODULES_DIR="$ROOT/usr/lib/modules/$(cat version)"

			# systemd expects the kernel here (hibernation, kernel-install).
			install -Dm644 "$(make -s image_name)" "$MODULES_DIR/vmlinuz"
			# Names the kernel for initramfs generators.
			echo linux | install -Dm644 /dev/stdin "$MODULES_DIR/pkgbase"

			ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$ROOT/usr" INSTALL_MOD_STRIP=1 \
				DEPMOD=/doesnt/exist modules_install # depmod runs on install
			rm "$MODULES_DIR/build"
		]], opts)
	elseif sub == "headers" then
		-- Arch's _package-headers: what out-of-tree modules (DKMS) need.
		cmd(kbuild_env .. [[
			BUILD_DIR="$ROOT/usr/lib/modules/$(cat version)/build"
			KARCH=x86

			install -Dt "$BUILD_DIR" -m644 .config Makefile Module.symvers \
				System.map version vmlinux tools/bpf/bpftool/vmlinux.h
			install -Dt "$BUILD_DIR/kernel" -m644 kernel/Makefile
			install -Dt "$BUILD_DIR/arch/$KARCH" -m644 "arch/$KARCH/Makefile"
			cp -t "$BUILD_DIR" -a scripts
			ln -srt "$BUILD_DIR" "$BUILD_DIR/scripts/gdb/vmlinux-gdb.py"

			if [ "$(scripts/config -s CONFIG_HAVE_STACK_VALIDATION)" = y ]; then
				install -Dt "$BUILD_DIR/tools/objtool" tools/objtool/objtool
			fi
			if [ "$(scripts/config -s CONFIG_DEBUG_INFO_BTF_MODULES)" = y ]; then
				install -Dt "$BUILD_DIR/tools/bpf/resolve_btfids" \
					tools/bpf/resolve_btfids/resolve_btfids
			fi

			cp -t "$BUILD_DIR" -a include
			cp -t "$BUILD_DIR/arch/$KARCH" -a "arch/$KARCH/include"
			install -Dt "$BUILD_DIR/arch/$KARCH/kernel" -m644 \
				"arch/$KARCH/kernel/asm-offsets.s"
			install -Dt "$BUILD_DIR/drivers/md" -m644 drivers/md/*.h
			install -Dt "$BUILD_DIR/net/mac80211" -m644 net/mac80211/*.h
			install -Dt "$BUILD_DIR/drivers/media/i2c" -m644 \
				drivers/media/i2c/msp3400-driver.h
			install -Dt "$BUILD_DIR/drivers/media/usb/dvb-usb" -m644 \
				drivers/media/usb/dvb-usb/*.h
			install -Dt "$BUILD_DIR/drivers/media/dvb-frontends" -m644 \
				drivers/media/dvb-frontends/*.h
			install -Dt "$BUILD_DIR/drivers/media/tuners" -m644 \
				drivers/media/tuners/*.h
			install -Dt "$BUILD_DIR/drivers/iio/common/hid-sensors" -m644 \
				drivers/iio/common/hid-sensors/*.h

			find . -name 'Kconfig*' -exec install -Dm644 {} "$BUILD_DIR/{}" \;

			if [ "$(scripts/config -s CONFIG_RUST)" = y ]; then
				install -Dt "$BUILD_DIR/rust" -m644 rust/*.rmeta
				install -Dt "$BUILD_DIR/rust" rust/*.so
			fi

			# Unstripped vDSO, without build-id symlinks.
			make INSTALL_MOD_PATH="$ROOT/usr" vdso_install link=

			for arch in "$BUILD_DIR"/arch/*/; do
				[ "$arch" = "$BUILD_DIR/arch/$KARCH/" ] && continue
				rm -r "$arch"
			done
			rm -r "$BUILD_DIR/Documentation"
			find -L "$BUILD_DIR" -type l -delete
			find "$BUILD_DIR" -type f -name '*.o' -delete

			# Strip the build tools like makepkg's defaults would.
			find "$BUILD_DIR" -type f -perm -u+x ! -name vmlinux -print0 |
				while IFS= read -r -d '' file; do
					case "$(file -Sib "$file")" in
					application/x-sharedlib\;*) strip --strip-unneeded "$file" ;;
					application/x-archive\;*) strip --strip-debug "$file" ;;
					application/x-executable\;*) strip --strip-all "$file" ;;
					application/x-pie-executable\;*) strip --strip-unneeded "$file" ;;
					esac
				done
			strip --strip-debug "$BUILD_DIR/vmlinux"

			mkdir -p "$ROOT/usr/src"
			ln -sr "$BUILD_DIR" "$ROOT/usr/src/linux"
		]], opts)
	elseif sub == "docs" then
		cmd(
			[[
			mkdir -p "$ROOT/usr/share/doc/linux"
			cp -a "linux-$UPSTREAM/Documentation"/. "$ROOT/usr/share/doc/linux/"
		]],
			opts
		)
	end
end

function test()
	cmd(
		[[
		cd "linux-$UPSTREAM"
		test -s "$(make -s image_name)"
		grep -qx "$UPSTREAM-parlex.*" version
	]],
		opts
	)
end

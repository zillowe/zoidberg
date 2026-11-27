local version = ZOI.VERSION or "2.42.4"
local sha512 = "3aea9ebd835b353e0c73356f0e4543ba4c3ad448e4f50a386c35cfaac81cbf45425b1a6c7552ed5673580acf2b58f8af2792f5b3019ffe478edd77c7ebf444dc"
-- Release signing key (Karel Zak), from upstream's published keys.
local signing_key = "B0C64D14301CC6EFAEDF60E4E4B71D5EEC39C284"

metadata({
	name = "util-linux",
	repo = "core",
	version = version,
	revision = "11",
	debug = { sub_package = true },
	description = "Miscellaneous system utilities for Linux",
	website = "https://github.com/util-linux/util-linux",
	license = "GPL-2.0-or-later AND LGPL-2.1-or-later AND BSD-2-Clause AND BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Karel Zak and others",
		website = "https://github.com/util-linux/util-linux",
	},
	bins = {
		"addpart",
		"agetty",
		"blkdiscard",
		"blkid",
		"blkzone",
		"blockdev",
		"cal",
		"cfdisk",
		"chcpu",
		"chfn",
		"chmem",
		"chsh",
		"col",
		"colcrt",
		"colrm",
		"column",
		"ctrlaltdel",
		"delpart",
		"dmesg",
		"eject",
		"fallocate",
		"fdformat",
		"fdisk",
		"fincore",
		"findfs",
		"findmnt",
		"flock",
		"fsck",
		"fsck.cramfs",
		"fsck.minix",
		"fsfreeze",
		"fstrim",
		"getopt",
		"hexdump",
		"hwclock",
		"ionice",
		"ipcmk",
		"ipcrm",
		"ipcs",
		"irqtop",
		"isosize",
		"kill",
		"last",
		"ldattach",
		"logger",
		"login",
		"look",
		"losetup",
		"lsblk",
		"lscpu",
		"lsipc",
		"lslocks",
		"lslogins",
		"lsmem",
		"lsns",
		"mcookie",
		"mesg",
		"mkfs",
		"mkfs.bfs",
		"mkfs.cramfs",
		"mkfs.minix",
		"mkswap",
		"more",
		"mount",
		"mountpoint",
		"namei",
		"newgrp",
		"nologin",
		"nsenter",
		"partx",
		"pivot_root",
		"prlimit",
		"raw",
		"readprofile",
		"rename",
		"renice",
		"resizepart",
		"rev",
		"rfkill",
		"rtcwake",
		"runuser",
		"script",
		"scriptlive",
		"scriptreplay",
		"setarch",
		"setpriv",
		"setsid",
		"setterm",
		"sfdisk",
		"su",
		"swaplabel",
		"swapoff",
		"swapon",
		"switch_root",
		"taskset",
		"uclampset",
		"ul",
		"umount",
		"unshare",
		"utmpdump",
		"uuidd",
		"uuidgen",
		"uuidparse",
		"waitpid",
		"wall",
		"wdctl",
		"whereis",
		"wipefs",
		"write",
		"zramctl",
	},
	-- Binaries of sub-packages other than the ones above.
	sub_bins = {
		libs = {},
		python = {},
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "libs", "python" },
	main_subs = { "main" },
	backup = {
		"${usrroot}/etc/pam.d/chfn",
		"${usrroot}/etc/pam.d/chsh",
		"${usrroot}/etc/pam.d/login",
		"${usrroot}/etc/pam.d/remote",
		"${usrroot}/etc/pam.d/runuser",
		"${usrroot}/etc/pam.d/runuser-l",
		"${usrroot}/etc/pam.d/su",
		"${usrroot}/etc/pam.d/su-l",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:asciidoctor",
					"pacman:bison",
					"pacman:curl",
					"pacman:cryptsetup",
					"pacman:diffutils",
					"pacman:file",
					"pacman:flex",
					"pacman:gcc",
					"pacman:libcap-ng",
					"pacman:libxcrypt",
					"pacman:meson",
					"pacman:ncurses",
					"pacman:ninja",
					"pacman:pam",
					"pacman:pkgconf",
					"pacman:po4a",
					"pacman:python",
					"pacman:readline",
					"pacman:sqlite",
					"pacman:systemd",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/file",
					"zoi:@core/glibc",
					"zoi:@core/libcap-ng",
					"zoi:@core/libxcrypt",
					"zoi:@core/ncurses",
					"zoi:@core/pam",
					"zoi:@core/readline",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/systemd:libs",
					"zoi:@core/util-linux:libs",
					"zoi:@core/zlib",
				},
			},
			libs = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/sqlite",
				},
			},
			-- pylibmount links libpython (meson `embed: true`). Arch ships it
			-- in util-linux-libs with python optional; it is split out here so
			-- libs (which python itself needs for libuuid) does not depend on
			-- python.
			python = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/python",
					"zoi:@core/util-linux:libs",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = { VER = version, SHA512 = sha512, SERIES = version:match("^(%d+%.%d+)") },
}

function prepare()
	local tarball = "util-linux-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/linux/utils/util-linux/v$SERIES" \
				"https://www.kernel.org/pub/linux/utils/util-linux/v$SERIES" \
				"https://mirrors.kernel.org/pub/linux/utils/util-linux/v$SERIES"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "util-linux-$VER.tar.xz"
		fetch "util-linux-$VER.tar.sign"
		echo "$SHA512  util-linux-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	-- kernel.org signs the uncompressed tar.
	cmd([[xz -dk "util-linux-$VER.tar.xz"]], opts)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "util-linux-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		meson setup "util-linux-$VER" build \
			--prefix=/usr \
			--buildtype=release \
			-Dfs-search-path=/usr/bin:/usr/local/bin \
			-Dlibuser=disabled \
			-Dlibutempter=disabled \
			-Dncurses=disabled \
			-Dncursesw=enabled \
			-Deconf=disabled \
			-Dcryptsetup=enabled \
			-Dcryptsetup-dlopen=enabled \
			-Dbuild-chfn-chsh=enabled \
			-Dbuild-line=disabled \
			-Dbuild-mesg=enabled \
			-Dbuild-newgrp=enabled \
			-Dbuild-vipw=disabled \
			-Dbuild-write=enabled \
			-Dbuild-python=enabled

		meson compile -C build -j"$(nproc)"
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			mkdir -p "$ROOT"/etc/pam.d "$ROOT"/usr/lib/{sysusers.d,udev/rules.d,systemd/system}

			DESTDIR="$ROOT" meson install -C build

			# Remove static libraries
			rm -f "$ROOT"/usr/lib/lib*.a

			# /usr/sbin is a symlink to bin on Parlex (merged /usr). Files recorded
			# under sbin would hide conflicts with packages using bin.
			if [ -d "$ROOT/usr/sbin" ] && [ ! -L "$ROOT/usr/sbin" ]; then
				mkdir -p "$ROOT/usr/bin"
				mv "$ROOT"/usr/sbin/* "$ROOT"/usr/bin/
				rmdir "$ROOT/usr/sbin"
			fi

			# Runtime libraries and headers go to the libs subpackage, the
			# libmount Python bindings to the python subpackage
			rm -rf "$ROOT"/usr/lib/lib*.so* "$ROOT"/usr/lib/pkgconfig "$ROOT"/usr/include "$ROOT"/usr/share/man/man3
			rm -rf "$ROOT"/usr/lib/python3*

			# Install PAM configurations
			install -m644 "${PKGLUADIR}/files/common.pam" "$ROOT/etc/pam.d/chfn"
			install -m644 "${PKGLUADIR}/files/common.pam" "$ROOT/etc/pam.d/chsh"
			install -m644 "${PKGLUADIR}/files/login.pam" "$ROOT/etc/pam.d/login"
			install -m644 "${PKGLUADIR}/files/remote.pam" "$ROOT/etc/pam.d/remote"
			install -m644 "${PKGLUADIR}/files/runuser.pam" "$ROOT/etc/pam.d/runuser"
			install -m644 "${PKGLUADIR}/files/runuser.pam" "$ROOT/etc/pam.d/runuser-l"
			install -m644 "${PKGLUADIR}/files/su.pam" "$ROOT/etc/pam.d/su"
			install -m644 "${PKGLUADIR}/files/su.pam" "$ROOT/etc/pam.d/su-l"

			# System integration files
			install -m644 "${PKGLUADIR}/files/util-linux.sysusers" "$ROOT/usr/lib/sysusers.d/util-linux.conf"
			install -m644 "${PKGLUADIR}/files/60-rfkill.rules" "$ROOT/usr/lib/udev/rules.d/60-rfkill.rules"
			install -m644 "${PKGLUADIR}/files/rfkill-unblock_.service" "$ROOT/usr/lib/systemd/system/rfkill-unblock@.service"
			install -m644 "${PKGLUADIR}/files/rfkill-block_.service" "$ROOT/usr/lib/systemd/system/rfkill-block@.service"
		]],
			opts
		)
	elseif sub == "libs" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/lib "$ROOT"/usr/share/man

			# Install into a scratch root and keep only the libraries, so this
			# does not depend on the main sub-package having been built first.
			TMP_DIR="$(mktemp -d)"
			DESTDIR="$TMP_DIR" meson install -C build --quiet
			cp -a "$TMP_DIR"/usr/lib/lib*.so* "$ROOT"/usr/lib/
			cp -a "$TMP_DIR"/usr/lib/pkgconfig "$ROOT"/usr/lib/
			cp -a "$TMP_DIR"/usr/include "$ROOT"/usr/
			if [ -d "$TMP_DIR"/usr/share/man/man3 ]; then
				cp -a "$TMP_DIR"/usr/share/man/man3 "$ROOT"/usr/share/man/
			fi
			rm -rf "$TMP_DIR"
		]],
			opts
		)
	elseif sub == "python" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/lib

			# Install into a scratch root and keep only the libmount bindings.
			TMP_DIR="$(mktemp -d)"
			DESTDIR="$TMP_DIR" meson install -C build --quiet
			cp -a "$TMP_DIR"/usr/lib/python3* "$ROOT"/usr/lib/
			rm -rf "$TMP_DIR"
		]],
			opts
		)
	end

	-- Every sub-package carries the upstream license texts.
	local src = "util-linux-" .. version
	zlicense(src .. "/COPYING")
	zlicense(src .. "/README.licensing")
	zlicense(src .. "/Documentation/licenses")
end

function test()
	cmd([[
		/usr/bin/lsblk --version || /usr/bin/lscpu --version || true
	]])
end

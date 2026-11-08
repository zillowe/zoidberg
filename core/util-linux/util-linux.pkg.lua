local version = ZOI.VERSION or "2.42.4"
local tag = "v" .. version
local git_url = "https://github.com/util-linux/util-linux.git"

metadata({
	name = "util-linux",
	repo = "core",
	version = version,
	revision = "5",
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
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "libs" },
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
					"pacman:diffutils",
					"pacman:file",
					"pacman:flex",
					"pacman:gcc",
					"pacman:git",
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
					"zoi:@core/systemd:libs",
					"zoi:@core/util-linux:libs",
				},
			},
			libs = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/sqlite",
				},
			},
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d util-linux ]; then
			git clone --depth 1 --branch "%s" "%s" util-linux
		fi

		cd util-linux
		sed -i '/dirty=/c dirty=' tools/git-version-gen 2>/dev/null || true
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e

		meson setup util-linux build \
			--prefix=/usr \
			--buildtype=release \
			-Dfs-search-path=/usr/bin:/usr/local/bin \
			-Dlibuser=disabled \
			-Dlibutempter=disabled \
			-Dncurses=disabled \
			-Dncursesw=enabled \
			-Deconf=disabled \
			-Dbuild-chfn-chsh=enabled \
			-Dbuild-line=disabled \
			-Dbuild-mesg=enabled \
			-Dbuild-newgrp=enabled \
			-Dbuild-vipw=enabled \
			-Dbuild-write=enabled

		meson compile -C build -j"$(nproc)"
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
			mkdir -p "$ROOT"/etc/pam.d "$ROOT"/usr/lib/{sysusers.d,udev/rules.d,systemd/system}

			DESTDIR="$ROOT" meson install -C build

			# Remove static libraries
			rm -f "$ROOT"/usr/lib/lib*.a

			# Stash runtime libraries for the libs subpackage
			mkdir -p split_libs/lib split_libs/include split_libs/man3
			mv "$ROOT"/usr/lib/lib*.so* split_libs/lib/ 2>/dev/null || true
			mv "$ROOT"/usr/lib/pkgconfig split_libs/lib/ 2>/dev/null || true
			mv "$ROOT"/usr/include split_libs/ 2>/dev/null || true
			mv "$ROOT"/usr/share/man/man3 split_libs/ 2>/dev/null || true

			# Install PAM configurations
			install -m644 "${PKGLUADIR}/common.pam" "$ROOT/etc/pam.d/chfn"
			install -m644 "${PKGLUADIR}/common.pam" "$ROOT/etc/pam.d/chsh"
			install -m644 "${PKGLUADIR}/login.pam" "$ROOT/etc/pam.d/login"
			install -m644 "${PKGLUADIR}/remote.pam" "$ROOT/etc/pam.d/remote"
			install -m644 "${PKGLUADIR}/runuser.pam" "$ROOT/etc/pam.d/runuser"
			install -m644 "${PKGLUADIR}/runuser.pam" "$ROOT/etc/pam.d/runuser-l"
			install -m644 "${PKGLUADIR}/su.pam" "$ROOT/etc/pam.d/su"
			install -m644 "${PKGLUADIR}/su.pam" "$ROOT/etc/pam.d/su-l"

			# System integration files
			install -m644 "${PKGLUADIR}/util-linux.sysusers" "$ROOT/usr/lib/sysusers.d/util-linux.conf"
			install -m644 "${PKGLUADIR}/60-rfkill.rules" "$ROOT/usr/lib/udev/rules.d/60-rfkill.rules"
			install -m644 "${PKGLUADIR}/rfkill-unblock_.service" "$ROOT/usr/lib/systemd/system/rfkill-unblock@.service"
			install -m644 "${PKGLUADIR}/rfkill-block_.service" "$ROOT/usr/lib/systemd/system/rfkill-block@.service"
		]],
			root
		))
	elseif sub == "libs" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/lib "$ROOT"/usr/share/man

			if [ -d split_libs ]; then
				cp -a split_libs/lib/* "$ROOT"/usr/lib/ 2>/dev/null || true
				cp -a split_libs/include "$ROOT"/usr/ 2>/dev/null || true
				cp -a split_libs/man3 "$ROOT"/usr/share/man/ 2>/dev/null || true
			fi
		]],
			root
		))
	end

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/lsblk --version || /usr/bin/lscpu --version || true
	]])
end

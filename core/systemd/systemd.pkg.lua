local version = ZOI.VERSION or "262.1"
local sha512 = "a4d696dc03d096b815b6780f910fab4e79e01b8414b26529a8585b437b27a50b10c1082e534f1cdcb8bbec330a2af0f98fdcacf189e75f64a157c8bbc4774976"
-- systemd publishes no release tarball (only signed git tags), so this is
-- GitHub's archive of the v<version> tag; stable point releases are tagged
-- in systemd/systemd itself. The hash matches the one Gentoo records for the
-- same archive (sys-apps/systemd Manifest).

metadata({
	name = "systemd",
	repo = "core",
	version = version,
	revision = "12",
	debug = { sub_package = true },
	description = "System and service manager for Linux",
	website = "https://systemd.io",
	license = "LGPL-2.1-or-later AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Lennart Poettering, Kay Sievers, and others",
		website = "https://github.com/systemd/systemd",
	},
	bins = {
		"bootctl",
		"busctl",
		"coredumpctl",
		"hostnamectl",
		"journalctl",
		"localectl",
		"loginctl",
		"machinectl",
		"networkctl",
		"oomctl",
		"portablectl",
		"resolvectl",
		"systemctl",
		"systemd-analyze",
		"systemd-ask-password",
		"systemd-cat",
		"systemd-cgls",
		"systemd-cgtop",
		"systemd-creds",
		"systemd-cryptenroll",
		"systemd-delta",
		"systemd-detect-virt",
		"systemd-dissect",
		"systemd-escape",
		"systemd-firstboot",
		"systemd-hwdb",
		"systemd-id128",
		"systemd-inhibit",
		"systemd-mount",
		"systemd-notify",
		"systemd-nspawn",
		"systemd-path",
		"systemd-repart",
		"systemd-run",
		"systemd-socket-activate",
		"systemd-stdio-bridge",
		"systemd-sysext",
		"systemd-sysusers",
		"systemd-tmpfiles",
		"systemd-umount",
		"systemd-vmspawn",
		"timedatectl",
		"udevadm",
		"userdbctl",
	},
	-- Binaries of sub-packages other than the ones above.
	sub_bins = {
		libs = {},
		resolvconf = { "resolvconf" },
		sysvcompat = {
			"halt",
			"init",
			"poweroff",
			"reboot",
			"shutdown",
		},
		ukify = { "ukify" },
	},
	sub_packages = { "main", "libs", "resolvconf", "sysvcompat", "ukify" },
	main_subs = { "main" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/systemd/coredump.conf",
		"${usrroot}/etc/systemd/homed.conf",
		"${usrroot}/etc/systemd/journald.conf",
		"${usrroot}/etc/systemd/journal-remote.conf",
		"${usrroot}/etc/systemd/journal-upload.conf",
		"${usrroot}/etc/systemd/logind.conf",
		"${usrroot}/etc/systemd/networkd.conf",
		"${usrroot}/etc/systemd/oomd.conf",
		"${usrroot}/etc/systemd/pstore.conf",
		"${usrroot}/etc/systemd/resolved.conf",
		"${usrroot}/etc/systemd/sleep.conf",
		"${usrroot}/etc/systemd/system.conf",
		"${usrroot}/etc/systemd/timesyncd.conf",
		"${usrroot}/etc/systemd/user.conf",
		"${usrroot}/etc/udev/iocost.conf",
		"${usrroot}/etc/udev/udev.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:acl",
					"pacman:audit",
					"pacman:bzip2",
					"pacman:bash-completion",
					"pacman:bpf",
					"pacman:clang",
					"pacman:cryptsetup",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:docbook-xsl",
					"pacman:gnutls",
					"pacman:gperf",
					"pacman:intltool",
					"pacman:iptables",
					"pacman:kexec-tools",
					"pacman:kmod",
					"pacman:libarchive",
					"pacman:libbpf",
					"pacman:libelf",
					"pacman:libgcrypt",
					"pacman:libgpg-error",
					"pacman:libidn2",
					"pacman:libmicrohttpd",
					"pacman:libseccomp",
					"pacman:libxcrypt",
					"pacman:libxslt",
					"pacman:linux-api-headers",
					"pacman:linux-headers",
					"pacman:llvm",
					"pacman:lz4",
					"pacman:meson",
					"pacman:ninja",
					"pacman:p11-kit",
					"pacman:pam",
					"pacman:pcre2",
					"pacman:pkgconf",
					"pacman:python-jinja",
					"pacman:python-lxml",
					"pacman:python-pefile",
					"pacman:python-pyelftools",
					"pacman:quota-tools",
					"pacman:rsync",
					"pacman:rust",
					"pacman:rust-bindgen",
					"pacman:shadow",
					"pacman:util-linux",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		-- No shared top-level list: it applies to every sub-package, which made
		-- systemd:libs depend on itself and on util-linux, kmod and hwdata.
		-- Most libraries are dlopen()ed by systemd, so a missing one does not
		-- fail at load time but silently disables the feature: every library
		-- of an enabled meson feature (see build()) is listed here.
		sub_packages = {
			main = {
				required = {
					"zoi:@core/acl",
					"zoi:@core/audit",
					"zoi:@core/bash",
					"zoi:@core/bzip2",
					"zoi:@core/cryptsetup",
					"zoi:@core/curl",
					"zoi:@core/dbus",
					-- dbus-units: dbus.service (Arch: dbus-broker-units)
					"zoi:@core/dbus-broker",
					"zoi:@core/elfutils:libelf",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/glibc",
					"zoi:@core/gnutls",
					"zoi:@core/hwdata",
					"zoi:@core/kbd",
					"zoi:@core/kmod",
					"zoi:@core/libarchive",
					"zoi:@core/libbpf",
					"zoi:@core/libgcrypt",
					"zoi:@core/libgpg-error",
					"zoi:@core/libidn2",
					"zoi:@core/libmicrohttpd",
					"zoi:@core/libseccomp",
					"zoi:@core/libxcrypt",
					"zoi:@core/lz4",
					"zoi:@core/openssl",
					"zoi:@core/p11-kit",
					"zoi:@core/pam",
					"zoi:@core/pcre2",
					"zoi:@core/systemd:libs",
					"zoi:@core/util-linux",
					"zoi:@core/util-linux:libs",
					"zoi:@core/xz",
					"zoi:@core/zlib",
					"zoi:@core/zstd",
				},
			},
			libs = {
				required = {
					"zoi:@core/gcc:libgcc",
					"zoi:@core/glibc",
					"zoi:@core/libgcrypt",
					"zoi:@core/libgpg-error",
					"zoi:@core/lz4",
					"zoi:@core/xz",
					"zoi:@core/zstd",
				},
			},
			resolvconf = {
				required = {
					"zoi:@core/systemd",
				},
			},
			sysvcompat = {
				required = {
					"zoi:@core/systemd",
				},
			},
			ukify = {
				required = {
					"zoi:@core/binutils",
					"zoi:@core/python",
					"zoi:@core/python-cryptography",
					"zoi:@core/python-pefile",
					"zoi:@core/systemd",
				},
			},
		},
	},
})

hooks({
	post_install = {
		[[
		if [ -x /usr/bin/systemd-machine-id-setup ] && [ ! -f /etc/machine-id ]; then
			/usr/bin/systemd-machine-id-setup 2>/dev/null || true
		fi
		if [ -x /usr/bin/systemd-sysusers ]; then
			/usr/bin/systemd-sysusers 2>/dev/null || true
		fi
		if [ -f /etc/shells ] && ! grep -qe '^/usr/bin/systemd-home-fallback-shell$' /etc/shells; then
			echo '/usr/bin/systemd-home-fallback-shell' >> /etc/shells
		fi
		# Enabled by default, as Arch does: a login prompt on the console
		# (getty@tty1), remote mounts, and the user database socket.
		systemctl enable getty@.service remote-fs.target systemd-userdbd.socket
		]],
	},
	post_remove = {
		[[
		if [ -f /etc/shells ]; then
			sed -i -r '/^\/usr\/bin\/systemd-home-fallback-shell$/d' /etc/shells 2>/dev/null || true
		fi
		]],
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/systemd/systemd/archive/refs/tags/v$VER.tar.gz" \
			-o "systemd-$VER.tar.gz"
		echo "$SHA512  systemd-$VER.tar.gz" | sha512sum -c -
		tar -xf "systemd-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	-- Every library feature is set explicitly, so meson never picks up a
	-- library just because it is on the build host. Enabled: as Arch, each
	-- with its runtime dependency declared above. Disabled: libraries
	-- Zoidberg does not package (AppArmor, libfido2, tpm2-tss, qrencode,
	-- libpwquality/passwdqc, libxkbcommon, polkit, SELinux, Xen); dbus and
	-- glib are only used by the test suite.
	cmd(
		[[
		meson setup "systemd-$VER" build \
			--prefix=/usr \
			--buildtype=release \
			-Dversion-tag="$VER-parlex" \
			-Dvcs-tag=false \
			-Dmode=release \
			-Dtests=false \
			-Dfuzz-tests=false \
			-Dacl=enabled \
			-Daudit=enabled \
			-Dblkid=enabled \
			-Dbzip2=enabled \
			-Delfutils=enabled \
			-Dfdisk=enabled \
			-Dgcrypt=enabled \
			-Dgnutls=enabled \
			-Dkmod=enabled \
			-Dlibarchive=enabled \
			-Dlibcrypt=enabled \
			-Dlibcryptsetup=enabled \
			-Dlibcryptsetup-plugins=enabled \
			-Dlibcurl=enabled \
			-Dlibmount=enabled \
			-Dmicrohttpd=enabled \
			-Dopenssl=enabled \
			-Dp11kit=enabled \
			-Dpam=enabled \
			-Dpcre2=enabled \
			-Dremote=enabled \
			-Dseccomp=enabled \
			-Dukify=enabled \
			-Dxz=enabled \
			-Dzlib=enabled \
			-Dzstd=enabled \
			-Dapparmor=disabled \
			-Ddbus=disabled \
			-Dglib=disabled \
			-Dlibfido2=disabled \
			-Dpasswdqc=disabled \
			-Dpolkit=disabled \
			-Dpwquality=disabled \
			-Dqrencode=disabled \
			-Dtpm2=disabled \
			-Dxkbcommon=disabled \
			-Dbootloader=enabled \
			-Dxenctrl=disabled \
			-Dbpf-framework=enabled \
			-Dima=false \
			-Dinstall-tests=false \
			-Dlibidn2=enabled \
			-Dlz4=enabled \
			-Dman=true \
			-Dselinux=disabled \
			-Dsshdprivsepdir=/usr/share/empty.sshd \
			-Dsysupdated=enabled \
			-Dcompat-sysv-interfaces=false \
			-Ddbuspolicydir=/usr/share/dbus-1/system.d \
			-Ddefault-dnssec=no \
			-Ddefault-kill-user-processes=false \
			-Ddefault-locale='C.UTF-8' \
			-Dlocalegen-path=/usr/bin/locale-gen \
			-Ddns-over-tls=openssl \
			-Dfallback-hostname='parlex' \
			-Dnologin-path=/usr/bin/nologin \
			-Drpmmacrosdir=no

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
			DESTDIR="$ROOT" meson install -C build --quiet

			# Runtime libraries moved to systemd-libs
			rm -rf "$ROOT"/usr/lib/lib{nss,systemd,udev}*.so*
			rm -rf "$ROOT"/usr/lib/pkgconfig
			rm -rf "$ROOT"/usr/include
			rm -rf "$ROOT"/usr/share/man/man3
			rm -rf "$ROOT"/usr/share/man/man8/*nss*

			# ukify moved to systemd-ukify
			rm -f "$ROOT"/usr/bin/ukify
			rm -rf "$ROOT"/usr/lib/systemd/ukify
			rm -f "$ROOT"/usr/share/man/man1/ukify.1*
			rm -f "$ROOT"/usr/lib/kernel/install.d/60-ukify.install

			# sysvcompat moved to systemd-sysvcompat
			rm -f "$ROOT"/usr/share/man/man1/init.1*
			rm -f "$ROOT"/usr/share/man/man8/{halt,poweroff,reboot,shutdown}.8*
			rm -f "$ROOT"/usr/bin/{halt,init,poweroff,reboot,shutdown}

			# resolvconf moved to systemd-resolvconf
			rm -f "$ROOT"/usr/bin/resolvconf
			rm -f "$ROOT"/usr/share/man/man1/resolvconf.1*

			# Avoid potential conflict with filesystem
			rm -f "$ROOT"/usr/share/factory/etc/{issue,nsswitch.conf}
			if [ -f "$ROOT"/usr/lib/tmpfiles.d/etc.conf ]; then
				sed -i -e '/^C \/etc\/nsswitch\.conf/d' -e '/^C \/etc\/issue/d' "$ROOT"/usr/lib/tmpfiles.d/etc.conf
			fi

			# Ship default preset
			mkdir -p "$ROOT"/usr/lib/systemd/system-preset
			echo 'disable *' > "$ROOT"/usr/lib/systemd/system-preset/99-default.preset

			# Journal dir
			mkdir -p "$ROOT"/var/log/journal
			chmod 2755 "$ROOT"/var/log/journal

			# Bootctl examples
			mkdir -p "$ROOT"/usr/share/systemd/bootctl
			if [ -f "${PKGLUADIR}/files/parlex.conf" ]; then
				install -m644 "${PKGLUADIR}/files/parlex.conf" "$ROOT"/usr/share/systemd/bootctl/
			fi
			if [ -f "${PKGLUADIR}/files/loader.conf" ]; then
				install -m644 "${PKGLUADIR}/files/loader.conf" "$ROOT"/usr/share/systemd/bootctl/
			fi
			if [ -f "${PKGLUADIR}/files/splash-parlex.bmp" ]; then
				install -m644 "${PKGLUADIR}/files/splash-parlex.bmp" "$ROOT"/usr/share/systemd/bootctl/
			fi

			# Hook runner script
			if [ -f "${PKGLUADIR}/files/systemd-hook" ]; then
				mkdir -p "$ROOT"/usr/lib/systemd "$ROOT"/usr/share/libalpm/scripts
				install -m755 "${PKGLUADIR}/files/systemd-hook" "$ROOT"/usr/lib/systemd/systemd-hook
				ln -sf /usr/lib/systemd/systemd-hook "$ROOT"/usr/share/libalpm/scripts/systemd-hook
			fi

			# PAM config
			if [ -f "${PKGLUADIR}/files/systemd-user.pam" ]; then
				mkdir -p "$ROOT"/usr/lib/pam.d
				install -m644 "${PKGLUADIR}/files/systemd-user.pam" "$ROOT"/usr/lib/pam.d/systemd-user
			fi

			mkdir -p "$ROOT"/etc/cryptsetup-keys.d
			chmod 0700 "$ROOT"/etc/cryptsetup-keys.d

			# Kernel install symlink
			ln -sf kernel-install "$ROOT"/usr/bin/installkernel
		]],
			opts
		)

		-- Transaction hooks bundled into package store
		zcp("${pkgluadir}/hooks/systemd-sysusers.hook.yaml", "${pkgstore}/hooks/systemd-sysusers.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-tmpfiles.hook.yaml", "${pkgstore}/hooks/systemd-tmpfiles.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-binfmt.hook.yaml", "${pkgstore}/hooks/systemd-binfmt.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-catalog.hook.yaml", "${pkgstore}/hooks/systemd-catalog.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-hwdb.hook.yaml", "${pkgstore}/hooks/systemd-hwdb.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-sysctl.hook.yaml", "${pkgstore}/hooks/systemd-sysctl.hook.yaml")
		zcp(
			"${pkgluadir}/hooks/systemd-daemon-reload-system.hook.yaml",
			"${pkgstore}/hooks/systemd-daemon-reload-system.hook.yaml"
		)
		zcp(
			"${pkgluadir}/hooks/systemd-daemon-reload-user.hook.yaml",
			"${pkgstore}/hooks/systemd-daemon-reload-user.hook.yaml"
		)
		zcp("${pkgluadir}/hooks/systemd-enqueue-marked.hook.yaml", "${pkgstore}/hooks/systemd-enqueue-marked.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-udev-reload.hook.yaml", "${pkgstore}/hooks/systemd-udev-reload.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-update.hook.yaml", "${pkgstore}/hooks/systemd-update.hook.yaml")
		zcp("${pkgluadir}/hooks/systemd-modules-load.hook.yaml", "${pkgstore}/hooks/systemd-modules-load.hook.yaml")

	elseif sub == "libs" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/lib "$ROOT"/usr/include "$ROOT"/usr/share/man/man3 "$ROOT"/usr/share/man/man8

			TMP_DIR="$(mktemp -d)"
			DESTDIR="$TMP_DIR" meson install -C build --quiet

			cp -a "$TMP_DIR"/usr/lib/lib{nss,systemd,udev}*.so* "$ROOT"/usr/lib/
			cp -a "$TMP_DIR"/usr/lib/pkgconfig "$ROOT"/usr/lib/
			cp -a "$TMP_DIR"/usr/include/* "$ROOT"/usr/include/
			cp -a "$TMP_DIR"/usr/share/man/man3/* "$ROOT"/usr/share/man/man3/
			cp -a "$TMP_DIR"/usr/share/man/man8/*nss* "$ROOT"/usr/share/man/man8/

			rm -rf "$TMP_DIR"
		]],
			opts
		)
	elseif sub == "resolvconf" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/share/man/man1
			ln -sf resolvectl "$ROOT"/usr/bin/resolvconf
			ln -sf resolvectl.1.gz "$ROOT"/usr/share/man/man1/resolvconf.1.gz 2>/dev/null || ln -sf resolvectl.1 "$ROOT"/usr/share/man/man1/resolvconf.1
		]],
			opts
		)
	elseif sub == "sysvcompat" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/share/man/man1 "$ROOT"/usr/share/man/man8
			ln -sf ../lib/systemd/systemd "$ROOT"/usr/bin/init
			for tool in halt poweroff reboot shutdown; do
				ln -sf systemctl "$ROOT"/usr/bin/"$tool"
			done

			if [ -f build/man/init.1 ]; then
				install -m644 build/man/init.1 "$ROOT"/usr/share/man/man1/
			fi
			for man in halt poweroff reboot shutdown; do
				if [ -f "build/man/${man}.8" ]; then
					install -m644 "build/man/${man}.8" "$ROOT"/usr/share/man/man8/
				fi
			done
		]],
			opts
		)
	elseif sub == "ukify" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/lib/systemd "$ROOT"/usr/share/man/man1 "$ROOT"/usr/lib/kernel/install.d

			TMP_DIR="$(mktemp -d)"
			DESTDIR="$TMP_DIR" meson install -C build --quiet

			# ukify is built unconditionally (-Dukify=enabled).
			cp -a "$TMP_DIR"/usr/bin/ukify "$ROOT"/usr/bin/
			cp -a "$TMP_DIR"/usr/lib/systemd/ukify "$ROOT"/usr/lib/systemd/
			cp -a "$TMP_DIR"/usr/share/man/man1/ukify.1* "$ROOT"/usr/share/man/man1/
			cp -a "$TMP_DIR"/usr/lib/kernel/install.d/60-ukify.install "$ROOT"/usr/lib/kernel/install.d/

			rm -rf "$TMP_DIR"
		]],
			opts
		)
	end

	-- Every sub-package carries the license texts (LGPL-2.1-or-later for
	-- the libraries, GPL-2.0-or-later for udev, plus the minor licenses in
	-- LICENSES/ such as MIT-0 and CC0-1.0).
	local src = "systemd-" .. version
	zlicense(src .. "/LICENSE.GPL2")
	zlicense(src .. "/LICENSE.LGPL2.1")
	zlicense(src .. "/LICENSES")
end

function test()
	cmd([[
		/usr/bin/systemctl --version || systemctl --version || true
	]])
end

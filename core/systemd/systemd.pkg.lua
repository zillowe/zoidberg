local version = ZOI.VERSION or "262.1"
local tag = "v" .. version
local git_url = "https://github.com/systemd/systemd.git"

metadata({
	name = "systemd",
	repo = "core",
	version = version,
	revision = "2",
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
					"pacman:apparmor",
					"pacman:audit",
					"pacman:bash-completion",
					"pacman:bpf",
					"pacman:clang",
					"pacman:cryptsetup",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:docbook-xsl",
					"pacman:git",
					"pacman:gnutls",
					"pacman:gperf",
					"pacman:intltool",
					"pacman:iptables",
					"pacman:kexec-tools",
					"pacman:kmod",
					"pacman:libarchive",
					"pacman:libbpf",
					"pacman:libelf",
					"pacman:libfido2",
					"pacman:libgcrypt",
					"pacman:libidn2",
					"pacman:libmicrohttpd",
					"pacman:libpwquality",
					"pacman:libseccomp",
					"pacman:libxcrypt",
					"pacman:libxkbcommon",
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
					"pacman:python-jinja",
					"pacman:python-lxml",
					"pacman:python-pefile",
					"pacman:python-pyelftools",
					"pacman:qrencode",
					"pacman:quota-tools",
					"pacman:rsync",
					"pacman:rust",
					"pacman:rust-bindgen",
					"pacman:shadow",
					"pacman:tpm2-tss",
					"pacman:util-linux",
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
			"zoi:@core/systemd:libs",
			"zoi:@core/bash",
			"zoi:@core/kmod",
			"zoi:@core/hwdata",
			"zoi:@core/util-linux",
			"zoi:@core/xz",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/systemd:libs",
					"zoi:@core/bash",
					"zoi:@core/kmod",
					"zoi:@core/hwdata",
					"zoi:@core/util-linux",
					"zoi:@core/xz",
				},
			},
			libs = {
				required = {
					"zoi:@core/glibc",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d systemd ]; then
			git clone --depth 1 --branch "%s" "%s" systemd
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e

		meson setup systemd build \
			--prefix=/usr \
			--buildtype=release \
			-Dversion-tag="]] .. version .. [[-parlex" \
			-Dvcs-tag=false \
			-Dmode=release \
			-Dapparmor=enabled \
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
			if [ -f "${PKGLUADIR}/parlex.conf" ]; then
				install -m644 "${PKGLUADIR}/parlex.conf" "$ROOT"/usr/share/systemd/bootctl/
			fi
			if [ -f "${PKGLUADIR}/loader.conf" ]; then
				install -m644 "${PKGLUADIR}/loader.conf" "$ROOT"/usr/share/systemd/bootctl/
			fi
			if [ -f "${PKGLUADIR}/splash-parlex.bmp" ]; then
				install -m644 "${PKGLUADIR}/splash-parlex.bmp" "$ROOT"/usr/share/systemd/bootctl/
			fi

			# Hook runner script
			if [ -f "${PKGLUADIR}/systemd-hook" ]; then
				mkdir -p "$ROOT"/usr/lib/systemd "$ROOT"/usr/share/libalpm/scripts
				install -m755 "${PKGLUADIR}/systemd-hook" "$ROOT"/usr/lib/systemd/systemd-hook
				ln -sf /usr/lib/systemd/systemd-hook "$ROOT"/usr/share/libalpm/scripts/systemd-hook
			fi

			# PAM config
			if [ -f "${PKGLUADIR}/systemd-user.pam" ]; then
				mkdir -p "$ROOT"/usr/lib/pam.d
				install -m644 "${PKGLUADIR}/systemd-user.pam" "$ROOT"/usr/lib/pam.d/systemd-user
			fi

			mkdir -p "$ROOT"/etc/cryptsetup-keys.d
			chmod 0700 "$ROOT"/etc/cryptsetup-keys.d

			# Kernel install symlink
			ln -sf kernel-install "$ROOT"/usr/bin/installkernel
		]],
			root
		))

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

		-- zlicense("LICENSE")
	elseif sub == "libs" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/lib "$ROOT"/usr/include "$ROOT"/usr/share/man/man3 "$ROOT"/usr/share/man/man8

			TMP_DIR="$(mktemp -d)"
			DESTDIR="$TMP_DIR" meson install -C build --quiet

			cp -a "$TMP_DIR"/usr/lib/lib{nss,systemd,udev}*.so* "$ROOT"/usr/lib/ 2>/dev/null || true
			cp -a "$TMP_DIR"/usr/lib/pkgconfig "$ROOT"/usr/lib/ 2>/dev/null || true
			cp -a "$TMP_DIR"/usr/include/* "$ROOT"/usr/include/ 2>/dev/null || true
			cp -a "$TMP_DIR"/usr/share/man/man3/* "$ROOT"/usr/share/man/man3/ 2>/dev/null || true
			cp -a "$TMP_DIR"/usr/share/man/man8/*nss* "$ROOT"/usr/share/man/man8/ 2>/dev/null || true

			rm -rf "$TMP_DIR"
		]],
			root
		))
	elseif sub == "resolvconf" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/share/man/man1
			ln -sf resolvectl "$ROOT"/usr/bin/resolvconf
			ln -sf resolvectl.1.gz "$ROOT"/usr/share/man/man1/resolvconf.1.gz 2>/dev/null || ln -sf resolvectl.1 "$ROOT"/usr/share/man/man1/resolvconf.1
		]],
			root
		))
	elseif sub == "sysvcompat" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
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
			root
		))
	elseif sub == "ukify" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/lib/systemd "$ROOT"/usr/share/man/man1 "$ROOT"/usr/lib/kernel/install.d

			TMP_DIR="$(mktemp -d)"
			DESTDIR="$TMP_DIR" meson install -C build --quiet

			[ -f "$TMP_DIR"/usr/bin/ukify ] && cp -a "$TMP_DIR"/usr/bin/ukify "$ROOT"/usr/bin/
			[ -d "$TMP_DIR"/usr/lib/systemd/ukify ] && cp -a "$TMP_DIR"/usr/lib/systemd/ukify "$ROOT"/usr/lib/systemd/
			cp -a "$TMP_DIR"/usr/share/man/man1/ukify.1* "$ROOT"/usr/share/man/man1/ 2>/dev/null || true
			[ -f "$TMP_DIR"/usr/lib/kernel/install.d/60-ukify.install ] && cp -a "$TMP_DIR"/usr/lib/kernel/install.d/60-ukify.install "$ROOT"/usr/lib/kernel/install.d/

			rm -rf "$TMP_DIR"
		]],
			root
		))
	end
end

function test()
	cmd([[
		/usr/bin/systemctl --version || systemctl --version || true
	]])
end

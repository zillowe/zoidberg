local version = ZOI.VERSION or "4.2.1"
local sha512 =
	"71c4ac50b471138da866a82a0fa45970cf26181962f005ae570bdbb76e7cd15b66f8ebeba75a075bf04e52b20d039f012e2bbf8b1055f44641c36897f132894d"

metadata({
	name = "audit",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "Userspace components of the audit framework",
	website = "https://github.com/linux-audit/audit-userspace",
	license = "GPL-2.0-or-later AND LGPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Linux Audit Project",
		website = "https://github.com/linux-audit/audit-userspace",
	},
	bins = {
		"aulast",
		"aulastlog",
		"aureport",
		"ausearch",
		"ausyscall",
		"auditctl",
		"auditd",
		"augenrules",
		"autrace",
		"auvirt",
	},
	-- Binaries of sub-packages other than the ones above.
	sub_bins = {
		python = {},
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "python" },
	main_subs = { "main" },
	backup = {
		"${usrroot}/etc/libaudit.conf",
		"${usrroot}/etc/audit/audit-stop.rules",
		"${usrroot}/etc/audit/auditd.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:krb5",
					"pacman:libcap-ng",
					"pacman:libldap",
					"pacman:libtool",
					"pacman:linux-api-headers",
					"pacman:make",
					"pacman:patch",
					"pacman:python",
					"pacman:swig",
					"pacman:systemd",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/bash",
					"zoi:@core/glibc",
					"zoi:@core/krb5",
					"zoi:@core/libcap-ng",
					"zoi:@core/openldap:libs",
				},
			},
			python = {
				required = {
					"zoi:@core/audit",
					"zoi:@core/glibc",
					"zoi:@core/python",
				},
			},
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/linux-audit/audit-userspace/archive/refs/tags/v$VER.tar.gz" \
			-o "audit-userspace-v$VER.tar.gz"
		echo "$SHA512  audit-userspace-v$VER.tar.gz" | sha512sum -c -
		tar -xf "audit-userspace-v$VER.tar.gz"
		cd "audit-userspace-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/audit-4.1.2-executable_paths.patch"
		autoreconf -fiv
	]],
		opts
	)
end

function build()
	-- As in Arch: GSSAPI (krb5) remote logging, the z/OS remote plugin
	-- (libldap) and the python bindings are enabled. Parlex ships no apparmor
	-- or liburing, so those stay disabled instead of linking build host
	-- copies.
	cmd(
		[[
		cd "audit-userspace-$VER"
		./configure \
			--enable-experimental \
			--enable-gssapi-krb5=yes \
			--enable-systemd=yes \
			--enable-zos-remote \
			--libexecdir=/usr/lib/audit \
			--prefix=/usr \
			--runstatedir=/run \
			--sbindir=/usr/bin \
			--sysconfdir=/etc \
			--with-aarch64 \
			--with-apparmor=no \
			--with-arm \
			--with-io_uring=no \
			--with-libcap-ng=yes \
			--with-nftables \
			--with-python3=yes
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"
	local src = "audit-userspace-" .. version

	if sub == "main" or sub == "" then
		cmd(
			[[
			mkdir -p "$ROOT"
			make -C "audit-userspace-$VER" DESTDIR="$ROOT" install

			install -vDm644 "$PKGLUADIR/files/audit.tmpfiles" "$ROOT/usr/lib/tmpfiles.d/audit.conf"
			rm -rf "$ROOT/usr/lib/audit"

			# The python bindings go to the python sub-package
			rm -rf "$ROOT"/usr/lib/python*

			# Factory defaults, restored by the tmpfiles rules when missing
			install -vdm755 "$ROOT/usr/share/factory/"
			cp -av "$ROOT/etc" "$ROOT/usr/share/factory/"
		]],
			opts
		)
		zdoc(src .. "/README.md")
		zdoc(src .. "/SECURITY.md")
		zdoc(src .. "/ChangeLog")
	elseif sub == "python" then
		cmd(
			[[
			# Install into a scratch root and keep only the python bindings, so
			# this does not depend on the main sub-package having been built.
			TMP_DIR="$(mktemp -d)"
			make -C "audit-userspace-$VER" DESTDIR="$TMP_DIR" install
			mkdir -p "$ROOT/usr/lib"
			cp -a "$TMP_DIR"/usr/lib/python* "$ROOT/usr/lib/"
			rm -rf "$TMP_DIR"
		]],
			opts
		)
	end

	zlicense(src .. "/COPYING")
	zlicense(src .. "/COPYING.LIB")
end

function test()
	cmd([[
		/usr/bin/auditctl -v || true
	]])
end

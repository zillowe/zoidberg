local version = ZOI.VERSION or "4.2.1"

metadata({
	name = "audit",
	repo = "core",
	version = version,
	revision = "2",
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
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
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
					"pacman:libcap-ng",
					"pacman:libtool",
					"pacman:linux-api-headers",
					"pacman:make",
					"pacman:patch",
					"pacman:systemd",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/libcap-ng",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d "audit-userspace-$VER" ]; then
			curl -sSfL "https://github.com/linux-audit/audit-userspace/archive/v$VER/audit-userspace-v$VER.tar.gz" -o "audit-userspace-v$VER.tar.gz"
			echo "71c4ac50b471138da866a82a0fa45970cf26181962f005ae570bdbb76e7cd15b66f8ebeba75a075bf04e52b20d039f012e2bbf8b1055f44641c36897f132894d  audit-userspace-v$VER.tar.gz" | sha512sum -c -
			tar -xf "audit-userspace-v$VER.tar.gz"
			patch -Np1 -d "audit-userspace-$VER" -i "$PKGLUADIR/audit-4.1.2-executable_paths.patch"
			cd "audit-userspace-$VER"
			autoreconf -fiv
		fi
	]])
end

function build()
	-- Parlex ships no krb5, apparmor, openldap, liburing or python, so the
	-- GSSAPI remote logging, z/OS plugin, apparmor and io_uring support and
	-- the python bindings are disabled instead of linking build host copies.
	sh([[
		cd "audit-userspace-$VER"
		./configure \
			--enable-experimental \
			--enable-gssapi-krb5=no \
			--enable-systemd=yes \
			--disable-zos-remote \
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
			--with-python3=no
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "audit-userspace-$VER" DESTDIR="$ROOT" install

		install -vDm644 "audit-userspace-$VER/README.md" "audit-userspace-$VER/SECURITY.md" "audit-userspace-$VER/ChangeLog" \
			-t "$ROOT/usr/share/doc/audit/"
		install -vDm644 "$PKGLUADIR/audit.tmpfiles" "$ROOT/usr/lib/tmpfiles.d/audit.conf"
		rm -rf "$ROOT/usr/lib/audit"

		# Factory defaults, restored by the tmpfiles rules when missing
		install -vdm755 "$ROOT/usr/share/factory/"
		cp -av "$ROOT/etc" "$ROOT/usr/share/factory/"
	]])
end

function test()
	cmd([[
		/usr/bin/auditctl -v || true
	]])
end

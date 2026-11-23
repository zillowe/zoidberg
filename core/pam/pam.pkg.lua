local version = ZOI.VERSION or "1.7.3"
local sha512 = "1f0946461b879886ecade76793377d97d6a3036960196e37bb4fb05d6e30552e17fe1e652c6b0e7b7b1ce159d75c00f35df1c197cfd6b0012e7e3bb1bd42f144"
-- Release signing key (Dmitry V. Levin), one of the Linux-PAM release keys
-- listed by Arch Linux.
local signing_key = "7BECFE3AF7B280BB52FF77F104BA4521C996DDE1"

metadata({
	name = "pam",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "PAM (Pluggable Authentication Modules) library",
	website = "https://github.com/linux-pam/linux-pam",
	license = "GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Linux-PAM developers",
		website = "https://github.com/linux-pam/linux-pam",
	},
	bins = {
		"faillock",
		"mkhomedir_helper",
		"pam_namespace_helper",
		"pam_timestamp_check",
		"pwhistory_helper",
		"unix_chkpwd",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/security/access.conf",
		"${usrroot}/etc/security/faillock.conf",
		"${usrroot}/etc/security/group.conf",
		"${usrroot}/etc/security/limits.conf",
		"${usrroot}/etc/security/namespace.conf",
		"${usrroot}/etc/security/namespace.init",
		"${usrroot}/etc/security/pwhistory.conf",
		"${usrroot}/etc/security/pam_env.conf",
		"${usrroot}/etc/security/time.conf",
		"${usrroot}/etc/environment",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:curl",
					"pacman:audit",
					"pacman:docbook-xml",
					"pacman:docbook-xsl",
					"pacman:docbook5-xml",
					"pacman:flex",
					"pacman:fop",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:libnsl",
					"pacman:libtirpc",
					"pacman:libxcrypt",
					"pacman:libxml2",
					"pacman:libxslt",
					"pacman:meson",
					"pacman:ninja",
					"pacman:systemd",
					"pacman:tar",
					"pacman:w3m",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/audit",
			"zoi:@core/glibc",
			"zoi:@core/libnsl",
			"zoi:@core/libtirpc",
			"zoi:@core/libxcrypt",
			"zoi:@core/pambase",
			"zoi:@core/systemd:libs",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "Linux-PAM-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/linux-pam/linux-pam/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "Linux-PAM-$VER.tar.xz"
		fetch "Linux-PAM-$VER.tar.xz.asc"
		echo "$SHA512  Linux-PAM-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "Linux-PAM-$VER.tar.xz"]], opts)
end

function build()
	-- With --auto-features enabled, auto features become hard requirements:
	-- i18n (glibc intl + gettext), docs (xsltproc, xmllint, xmlcatalog,
	-- docbook catalogs, w3m), audit (libaudit), pam_unix (libxcrypt) and NIS
	-- support in pam_unix (libnsl + libtirpc, as in Arch). openssl defaults
	-- to disabled.
	cmd(
		[[
		rm -rf build
		meson setup \
			--prefix /usr \
			--libexecdir lib \
			--sbindir bin \
			--buildtype plain \
			--auto-features enabled \
			--wrap-mode nodownload \
			-D b_pie=true \
			-Dlogind=enabled \
			-Deconf=disabled \
			-Dselinux=disabled \
			-Delogind=disabled \
			-Dpam_userdb=disabled \
			-Dpwaccess=disabled \
			-Dvendordir='' \
			"Linux-PAM-$VER" build
		meson compile -C build
	]],
		opts
	)
end

function package()
	cmd(
		[[
		meson install -C build --destdir "$ROOT"
		install -Dm644 "$PKGLUADIR/files/pam.tmpfiles" "$ROOT/usr/lib/tmpfiles.d/pam.conf"
		rm -f "$ROOT"/usr/share/doc/Linux-PAM/*.pdf
		chmod +s "$ROOT/usr/bin/unix_chkpwd"
		find "$ROOT" -type d -empty -delete
	]],
		opts
	)
	zlicense("Linux-PAM-" .. version .. "/COPYING")
end

function test()
	cmd([[
		test -e /usr/lib/libpam.so.0 || true
	]])
end

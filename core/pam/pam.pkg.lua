local version = ZOI.VERSION or "1.7.3"

metadata({
	name = "pam",
	repo = "core",
	version = version,
	revision = "1",
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
					"pacman:audit",
					"pacman:docbook-xml",
					"pacman:docbook-xsl",
					"pacman:docbook5-xml",
					"pacman:flex",
					"pacman:fop",
					"pacman:gcc",
					"pacman:git",
					"pacman:libxcrypt",
					"pacman:libxslt",
					"pacman:meson",
					"pacman:ninja",
					"pacman:systemd",
					"pacman:w3m",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/audit",
			"zoi:@core/glibc",
			"zoi:@core/libxcrypt",
			"zoi:@core/pambase",
			"zoi:@core/systemd:libs",
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
		if [ ! -d pam ]; then
			git clone --depth 1 --branch "v$VER" https://github.com/linux-pam/linux-pam.git pam
		fi
	]])
end

function build()
	-- Parlex ships no libtirpc/libnsl, so NIS support is disabled instead of
	-- linking the build host's copies.
	sh([[
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
			-Dnis=disabled \
			-Dpam_userdb=disabled \
			-Dpwaccess=disabled \
			-Dvendordir='' \
			pam build
		meson compile -C build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		meson install -C build --destdir "$ROOT"
		install -Dm644 "$PKGLUADIR/pam.tmpfiles" "$ROOT/usr/lib/tmpfiles.d/pam.conf"
		rm -f "$ROOT"/usr/share/doc/Linux-PAM/*.pdf
		chmod +s "$ROOT/usr/bin/unix_chkpwd"
		find "$ROOT" -type d -empty -delete
	]])
end

function test()
	cmd([[
		test -e /usr/lib/libpam.so.0 || true
	]])
end

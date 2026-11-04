local version = ZOI.VERSION or "1.9.17.p2"
local raw_version = string.gsub(version, "%.p", "p")
local tar_url = string.format("https://www.sudo.ws/sudo/dist/sudo-%s.tar.gz", raw_version)

metadata({
	name = "sudo",
	repo = "core",
	version = version,
	revision = "9",
	description = "Give certain users the ability to run some commands as root",
	website = "https://www.sudo.ws/sudo/",
	license = "ISC",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Todd C. Miller",
		website = "https://www.sudo.ws/sudo/",
	},
	bins = {
		"cvtsudoers",
		"sudo",
		"sudoedit",
		"sudoreplay",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/pam.d/sudo",
		"${usrroot}/etc/sudo.conf",
		"${usrroot}/etc/sudo_logsrvd.conf",
		"${usrroot}/etc/sudoers",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:libldap",
					"pacman:make",
					"pacman:openssl",
					"pacman:pam",
					"pacman:patch",
					"pacman:tar",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/zlib",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "sudo-%s" ]; then
			curl -sSfL "%s" -o "sudo-%s.tar.gz"
			tar -xf "sudo-%s.tar.gz"
		fi

		cd "sudo-%s"
		if [ ! -f .patched ]; then
			patch -Np1 -i "${PKGLUADIR}/openssl-4.patch" || true
			touch .patched
		fi
	]],
		raw_version,
		tar_url,
		raw_version,
		raw_version,
		raw_version
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "sudo-%s"

		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--libexecdir=/usr/lib \
			--with-rundir=/run/sudo \
			--with-vardir=/var/db/sudo \
			--with-logfac=auth \
			--enable-tmpfiles.d \
			--with-pam \
			--with-sssd \
			--with-ldap \
			--with-ldap-conf-file=/etc/openldap/ldap.conf \
			--with-env-editor \
			--with-passprompt="[sudo] password for %%p: " \
			--with-secure-path-value=/usr/local/sbin:/usr/local/bin:/usr/bin \
			--with-all-insults

		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool 2>/dev/null || true
		make -j"$(nproc)"
	]],
		raw_version
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"/etc/pam.d "$ROOT"/usr/lib/systemd/system "$ROOT"/usr/share/licenses/sudo

		make -C "sudo-%s" DESTDIR="$ROOT" install

		install -m644 "${PKGLUADIR}/sudo_logsrvd.service" "$ROOT/usr/lib/systemd/system/sudo_logsrvd.service"
		install -m644 "${PKGLUADIR}/sudo.pam" "$ROOT/etc/pam.d/sudo"

		rm -f "$ROOT/etc/sudoers.dist"
		rm -rf "$ROOT/run"
	]],
		root,
		raw_version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/sudo --version || sudo --version
	]])
end

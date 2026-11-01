local version = ZOI.VERSION or "10.6p1"
local tar_url = string.format("https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-%s.tar.gz", version)

metadata({
	name = "openssh",
	repo = "core",
	version = version,
	revision = "1",
	description = "SSH protocol implementation for remote login, command execution and file transfer",
	website = "https://www.openssh.com/portable.html",
	license = "SSH",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The OpenSSH Project",
		website = "https://www.openssh.com",
	},
	bins = {
		"findssl.sh",
		"scp",
		"sftp",
		"slogin",
		"ssh",
		"ssh-add",
		"ssh-agent",
		"ssh-copy-id",
		"ssh-keygen",
		"ssh-keyscan",
		"sshd",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/pam.d/sshd",
		"${usrroot}/etc/ssh/ssh_config",
		"${usrroot}/etc/ssh/sshd_config",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:gcc",
					"pacman:krb5",
					"pacman:libedit",
					"pacman:libfido2",
					"pacman:libxcrypt",
					"pacman:make",
					"pacman:openssl",
					"pacman:pam",
					"pacman:tar",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/openssl",
			"zoi:@core/zlib",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "openssh-%s" ]; then
			curl -sSL "%s" | tar -xz
		fi

		cd "openssh-%s"
		sed -i '/^#.*\$.*\$$/d' ssh_config sshd_config 2>/dev/null || true

		printf "# Include drop-in configurations\nInclude /etc/ssh/sshd_config.d/*.conf\n" | cat - sshd_config > sshd_config.tmp && mv sshd_config.tmp sshd_config
		printf "# Include drop-in configurations\nInclude /etc/ssh/ssh_config.d/*.conf\n" | cat - ssh_config > ssh_config.tmp && mv ssh_config.tmp ssh_config
	]],
		version,
		tar_url,
		version
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "openssh-%s"

		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--libexecdir=/usr/lib/ssh \
			--sysconfdir=/etc/ssh \
			--disable-strip \
			--disable-lastlog \
			--with-pam \
			--with-libedit \
			--with-security-key-builtin \
			--with-privsep-user=nobody \
			--with-privsep-path=/usr/share/empty.sshd \
			--with-pid-dir=/run \
			--with-default-path='/usr/local/sbin:/usr/local/bin:/usr/bin'

		make -j"$(nproc)"
	]],
		version
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		cd "openssh-%s"

		make DESTDIR="$ROOT" install

		mkdir -p "$ROOT"/etc/ssh/sshd_config.d "$ROOT"/etc/ssh/ssh_config.d "$ROOT"/etc/pam.d
		mkdir -p "$ROOT"/usr/lib/systemd/system "$ROOT"/usr/lib/systemd/user "$ROOT"/usr/lib/tmpfiles.d

		if [ -f "${PKGLUADIR}/99-parlex.conf" ]; then
			install -m644 "${PKGLUADIR}/99-parlex.conf" "$ROOT"/etc/ssh/sshd_config.d/99-parlex.conf
		fi
		if [ -f "${PKGLUADIR}/sshd.pam" ]; then
			install -m644 "${PKGLUADIR}/sshd.pam" "$ROOT"/etc/pam.d/sshd
		fi
		if [ -f "${PKGLUADIR}/sshdgenkeys.service" ]; then
			install -m644 "${PKGLUADIR}/sshdgenkeys.service" "$ROOT"/usr/lib/systemd/system/
		fi
		if [ -f "${PKGLUADIR}/sshd.service" ]; then
			install -m644 "${PKGLUADIR}/sshd.service" "$ROOT"/usr/lib/systemd/system/
		fi
		if [ -f "${PKGLUADIR}/sshd@.service" ]; then
			install -m644 "${PKGLUADIR}/sshd@.service" "$ROOT"/usr/lib/systemd/system/
		fi
		if [ -f "${PKGLUADIR}/ssh-agent.service" ]; then
			install -m644 "${PKGLUADIR}/ssh-agent.service" "$ROOT"/usr/lib/systemd/user/
		fi
		if [ -f "${PKGLUADIR}/ssh-agent.socket" ]; then
			install -m644 "${PKGLUADIR}/ssh-agent.socket" "$ROOT"/usr/lib/systemd/user/
		fi
		if [ -f "${PKGLUADIR}/openssh.tmpfiles" ]; then
			install -m644 "${PKGLUADIR}/openssh.tmpfiles" "$ROOT"/usr/lib/tmpfiles.d/openssh.conf
		fi

		if [ -f contrib/findssl.sh ]; then
			install -m755 contrib/findssl.sh "$ROOT"/usr/bin/
		fi
		if [ -f contrib/ssh-copy-id ]; then
			install -m755 contrib/ssh-copy-id "$ROOT"/usr/bin/
			if [ -f contrib/ssh-copy-id.1 ]; then
				mkdir -p "$ROOT"/usr/share/man/man1
				install -m644 contrib/ssh-copy-id.1 "$ROOT"/usr/share/man/man1/
			fi
		fi
	]],
		root,
		version
	))

	zcp("${pkgluadir}/hooks/openssh-restart-sshd.hook.yaml", "${pkgstore}/hooks/openssh-restart-sshd.hook.yaml")

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/ssh -V || ssh -V || true
	]])
end

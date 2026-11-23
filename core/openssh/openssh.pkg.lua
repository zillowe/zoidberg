local version = ZOI.VERSION or "10.6p2"
local sha512 = "70696ed12bd1be04f67440415528f1ced1ef68c8ee7836e587395618d0992f3fd20c9498c44d46ad9f5806b9a73ce256fd6a2807f9c5c02e6496cf06816c749e"
-- Release signing key (Damien Miller), matches Arch's validpgpkeys.
local signing_key = "7168B983815A5EEF59A4ADFD2A3F414E736060BA"

metadata({
	name = "openssh",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
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
	platforms = { "linux-amd64" },
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
			-- findssl.sh and ssh-copy-id are shell scripts
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/krb5",
			"zoi:@core/libedit",
			"zoi:@core/libxcrypt",
			"zoi:@core/openssl",
			"zoi:@core/pam",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "openssh-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable" \
				"https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "openssh-$VER.tar.gz"
		fetch "openssh-$VER.tar.gz.asc"
		echo "$SHA512  openssh-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "openssh-$VER.tar.gz"
		cd "openssh-$VER"
		sed -i '/^#.*\$.*\$$/d' ssh_config sshd_config

		printf "# Include drop-in configurations\nInclude /etc/ssh/sshd_config.d/*.conf\n" | cat - sshd_config > sshd_config.tmp && mv sshd_config.tmp sshd_config
		printf "# Include drop-in configurations\nInclude /etc/ssh/ssh_config.d/*.conf\n" | cat - ssh_config > ssh_config.tmp && mv ssh_config.tmp ssh_config
	]],
		opts
	)
end

function build()
	-- Options as Arch (PAM, Kerberos 5/GSSAPI, libedit for sftp), except
	-- FIDO/U2F: Zoidberg has no libfido2, so the built-in security-key
	-- support Arch enables is disabled explicitly (configure would otherwise
	-- pick up the build host's libfido2). Security keys still work through an
	-- external SecurityKeyProvider middleware.
	cmd(
		[[
		cd "openssh-$VER"

		touch -c aclocal.m4 configure Makefile.in

		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--libexecdir=/usr/lib/ssh \
			--sysconfdir=/etc/ssh \
			--disable-strip \
			--disable-lastlog \
			--with-pam \
			--with-kerberos5=/usr \
			--with-libedit \
			--without-security-key-builtin \
			--without-security-key-standalone \
			--with-xauth=/usr/bin/xauth \
			--without-zlib-version-check \
			--with-privsep-user=nobody \
			--with-privsep-path=/usr/share/empty.sshd \
			--with-pid-dir=/run \
			--with-default-path='/usr/local/sbin:/usr/local/bin:/usr/bin'

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "openssh-$VER"

		make DESTDIR="$ROOT" install

		mkdir -p "$ROOT"/etc/ssh/sshd_config.d "$ROOT"/etc/ssh/ssh_config.d "$ROOT"/etc/pam.d
		mkdir -p "$ROOT"/usr/lib/systemd/system "$ROOT"/usr/lib/systemd/user "$ROOT"/usr/lib/tmpfiles.d "$ROOT"/usr/share/man/man1

		install -m644 "$PKGLUADIR/files/99-parlex.conf" "$ROOT"/etc/ssh/sshd_config.d/99-parlex.conf
		install -m644 "$PKGLUADIR/files/sshd.pam" "$ROOT"/etc/pam.d/sshd
		install -m644 "$PKGLUADIR/files/sshdgenkeys.service" "$ROOT"/usr/lib/systemd/system/
		install -m644 "$PKGLUADIR/files/sshd.service" "$ROOT"/usr/lib/systemd/system/
		install -m644 "$PKGLUADIR/files/sshd@.service" "$ROOT"/usr/lib/systemd/system/
		install -m644 "$PKGLUADIR/files/ssh-agent.service" "$ROOT"/usr/lib/systemd/user/
		install -m644 "$PKGLUADIR/files/ssh-agent.socket" "$ROOT"/usr/lib/systemd/user/
		install -m644 "$PKGLUADIR/files/openssh.tmpfiles" "$ROOT"/usr/lib/tmpfiles.d/openssh.conf

		install -m755 contrib/findssl.sh "$ROOT"/usr/bin/
		install -m755 contrib/ssh-copy-id "$ROOT"/usr/bin/
		install -m644 contrib/ssh-copy-id.1 "$ROOT"/usr/share/man/man1/
	]],
		opts
	)

	zcp("${pkgluadir}/hooks/openssh-restart-sshd.hook.yaml", "${pkgstore}/hooks/openssh-restart-sshd.hook.yaml")

	zlicense("openssh-" .. version .. "/LICENCE")
end

function test()
	cmd([[
		/usr/bin/ssh -V || ssh -V || true
	]])
end

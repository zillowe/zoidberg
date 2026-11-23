local version = ZOI.VERSION or "1.22.3"
local sha512 = "0276d83dee90e76d50a506d22901e658212094c1191fc09b8510273b4bfc56195ab1dd1c80b5fd8288b4aa9323c62f0b60ab3f6227ea113b4712bc54cb144abb"
-- Upstream signs releases (key C4493CB739F4A89F9852CBC20CBA08575F8372DF,
-- Greg Hudson, listed in Arch's validpgpkeys; it is the issuer of the
-- 1.22.3 .asc), but the key is only bound with SHA-1 self-signatures, which
-- Zoi's verifier rejects. The hash matches the one Gentoo records for the
-- same tarball (app-crypt/mit-krb5 Manifest); the pinned hash is the trust
-- anchor.

metadata({
	name = "krb5",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "The Kerberos network authentication system",
	website = "https://web.mit.edu/kerberos/",
	license = "MIT AND BSD-2-Clause AND BSD-3-Clause AND ISC AND OLDAP-2.8",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Massachusetts Institute of Technology",
		website = "https://web.mit.edu/kerberos/",
	},
	bins = {
		"gss-client",
		"gss-server",
		"k5srvutil",
		"kadmin",
		"kadmin.local",
		"kadmind",
		"kdb5_ldap_util",
		"kdb5_util",
		"kdestroy",
		"kinit",
		"klist",
		"kpasswd",
		"kprop",
		"kpropd",
		"kproplog",
		"krb5-config",
		"krb5kdc",
		"ksu",
		"kswitch",
		"ktutil",
		"kvno",
		"sclient",
		"sim_client",
		"sim_server",
		"sserver",
		"uuclient",
		"uuserver",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/krb5.conf",
		"${usrroot}/var/lib/krb5kdc/kdc.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:e2fsprogs",
					"pacman:gcc",
					"pacman:keyutils",
					"pacman:libldap",
					"pacman:lmdb",
					"pacman:make",
					"pacman:openssl",
					"pacman:perl",
					"pacman:pkgconf",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/e2fsprogs",
			"zoi:@core/glibc",
			"zoi:@core/keyutils",
			"zoi:@core/lmdb",
			"zoi:@core/openldap:libs",
			"zoi:@core/openssl",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = { VER = version, SHA512 = sha512, SERIES = version:match("^(%d+%.%d+)") },
}

function prepare()
	-- The OpenSSL 4 fixes Arch carries on 1.22.2 are part of 1.22.3.
	cmd(
		[[
		fetch() {
			for base in \
				"https://kerberos.org/dist/krb5/$SERIES" \
				"https://web.mit.edu/kerberos/dist/krb5/$SERIES"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "krb5-$VER.tar.gz"
		echo "$SHA512  krb5-$VER.tar.gz" | sha512sum -c -
		tar -xf "krb5-$VER.tar.gz"
		cd "krb5-$VER"
		# FS#25384
		sed -i "/KRB5ROOT=/s/\/local//" src/util/ac_check_krb5.m4
	]],
		opts
	)
end

function build()
	-- Parlex ships no libverto, so krb5's bundled verto (with its built-in
	-- event loop) is used instead of Arch's --with-system-verto; it is
	-- forced off so the build host's libverto is not picked up.
	cmd(
		[[
		cd "krb5-$VER/src"
		export CFLAGS="${CFLAGS:--O2 -pipe} -fPIC -fno-strict-aliasing -fstack-protector-all -std=gnu17"
		export WARN_CFLAGS=""
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--sysconfdir=/etc \
			--localstatedir=/var/lib \
			--enable-shared \
			--with-system-et \
			--with-system-ss \
			--disable-rpath \
			--without-tcl \
			--enable-dns-for-realm \
			--with-keyutils \
			--with-ldap \
			--with-lmdb \
			--without-system-verto
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "krb5-$VER/src"
		make DESTDIR="$ROOT" EXAMPLEDIR=/usr/share/doc/krb5/examples install

		# Fix FS#29889
		install -m644 plugins/kdb/ldap/libkdb_ldap/kerberos.ldif plugins/kdb/ldap/libkdb_ldap/kerberos.schema \
			"$ROOT/usr/share/doc/krb5/examples"

		install -Dpm644 config-files/krb5.conf -t "$ROOT/etc"
		install -Dpm644 config-files/kdc.conf -t "$ROOT/var/lib/krb5kdc"

		install -Dm644 util/ac_check_krb5.m4 -t "$ROOT/usr/share/aclocal"

		# systemd units (from Arch Linux)
		install -Dm644 "$PKGLUADIR"/files/krb5-kadmind.service "$PKGLUADIR"/files/krb5-kdc.service \
			"$PKGLUADIR"/files/krb5-kpropd.service "$PKGLUADIR"/files/krb5-kpropd@.service \
			"$PKGLUADIR"/files/krb5-kpropd.socket -t "$ROOT/usr/lib/systemd/system"

		# Empty directories (Arch: !emptydirs)
		find "$ROOT" -depth -type d -empty -delete
	]],
		opts
	)
	zlicense("krb5-" .. version .. "/NOTICE")
end

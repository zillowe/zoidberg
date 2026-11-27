local version = ZOI.VERSION or "2.7.2"
-- sha512 computed from the downloaded release (verified against the
-- signature below); its sha256 matches Arch's openldap 2.7.2 .SRCINFO.
local sha512 = "3653a97a9fb987d2015a9c9316a86a24fcc1e8f455b752e69790e4d692daaab330cf361fc1869cf089d3de6a42e0f381658cea5bea110b54841f751b04551821"
-- Release signing key (OpenLDAP Project), from upstream's published key
-- (https://www.openldap.org/software/download/OpenLDAP/gpg-pubkey.txt);
-- matches Arch's validpgpkeys.
local signing_key = "3CE269B5398BC8B785645E987F67D5FD1CE1CBCE"

-- Arch splits this into `libldap` (client libraries) and `openldap` (server
-- and tools). Here `libs` is the client library sub-package that other
-- packages depend on (`zoi:@core/openldap:libs`); `main` is slapd + tools.
metadata({
	name = "openldap",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Lightweight Directory Access Protocol (LDAP) client and server",
	website = "https://www.openldap.org/",
	license = "OLDAP-2.8",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The OpenLDAP Foundation",
		website = "https://www.openldap.org/",
	},
	bins = {
		"ldapadd",
		"ldapcompare",
		"ldapdelete",
		"ldapexop",
		"ldapmodify",
		"ldapmodrdn",
		"ldappasswd",
		"ldapsearch",
		"ldapurl",
		"ldapvc",
		"ldapwhoami",
		"slapacl",
		"slapadd",
		"slapauth",
		"slapcat",
		"slapd",
		"slapdn",
		"slapindex",
		"slapmodify",
		"slappasswd",
		"slapschema",
		"slaptest",
	},
	-- Binaries of sub-packages other than the ones above.
	sub_bins = {
		libs = {},
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "libs" },
	main_subs = { "main" },
	backup = {
		"${usrroot}/etc/openldap/ldap.conf",
		"${usrroot}/etc/openldap/slapd.conf",
		"${usrroot}/etc/openldap/slapd.ldif",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libsasl",
					"pacman:libtool",
					"pacman:libxcrypt",
					"pacman:make",
					"pacman:openssl",
					"pacman:perl",
					"pacman:systemd",
					"pacman:tar",
					"pacman:util-linux",
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
					"zoi:@core/cyrus-sasl:libs",
					"zoi:@core/glibc",
					"zoi:@core/libtool",
					"zoi:@core/libxcrypt",
					"zoi:@core/openldap:libs",
					"zoi:@core/openssl",
					"zoi:@core/perl",
					"zoi:@core/systemd:libs",
					"zoi:@core/util-linux:libs",
				},
			},
			libs = {
				required = {
					"zoi:@core/cyrus-sasl:libs",
					"zoi:@core/glibc",
					"zoi:@core/openssl",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

-- Extra modules from contrib/slapd-modules, as built by Arch.
local extra_modules = "nssov autogroup lastbind lastmod passwd/sha2 passwd/pbkdf2 passwd/totp allowed noopsrch"
opts.env.EXTRA_MODULES = extra_modules

function prepare()
	local tarball = "openldap-" .. version .. ".tgz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.openldap.org/software/download/OpenLDAP/openldap-release"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "openldap-$VER.tgz"
		fetch "openldap-$VER.tgz.asc"
		echo "$SHA512  openldap-$VER.tgz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "openldap-$VER.tgz"
		cd "openldap-$VER"

		# Change library permissions from 0644 to 0755
		sed -i 's|-m 644 $(LIBRARY)|-m 755 $(LIBRARY)|' libraries/liblber/Makefile.in libraries/libldap/Makefile.in

		# Change the rundir to /run/openldap
		sed -i 's|#define LDAPI_SOCK LDAP_RUNDIR LDAP_DIRSEP "run" LDAP_DIRSEP "ldapi"|#define LDAPI_SOCK LDAP_DIRSEP "run" LDAP_DIRSEP "openldap" LDAP_DIRSEP "ldapi"|' include/ldap_defaults.h
		sed -i 's|%LOCALSTATEDIR%/run|/run/openldap|' servers/slapd/slapd.conf servers/slapd/slapd.ldif
		sed -i 's|-$(MKDIR) $(DESTDIR)$(localstatedir)/run|-$(MKDIR) $(DESTDIR)/run/openldap|' servers/slapd/Makefile.in

		# Adapt the upstream systemd service
		sed -i -e "s|EnvironmentFile.*|EnvironmentFile=-/etc/conf.d/slapd|" -e "s/slapd -d 0/\0 -u ldap -g ldap/" servers/slapd/slapd.service
	]],
		opts
	)
end

function build()
	-- Difference from Arch: Argon2 password hashing is disabled because it
	-- needs libsodium, which Parlex does not ship. WiredTiger is disabled as
	-- in Arch. (2.7 removed the SQL backend, so unixODBC is not needed.)
	cmd(
		[[
		cd "openldap-$VER"
		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--sysconfdir=/etc \
			--localstatedir=/var/lib/openldap \
			--sbindir=/usr/bin \
			--enable-dynamic \
			--enable-syslog \
			--enable-ipv6 \
			--enable-local \
			--enable-crypt \
			--enable-spasswd \
			--enable-modules \
			--enable-backends \
			--disable-wt \
			--disable-argon2 \
			--enable-overlays=mod \
			--with-cyrus-sasl \
			--with-systemd \
			--with-tls=openssl \
			--with-threads

		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool

		make

		for module in $EXTRA_MODULES; do
			make -C "contrib/slapd-modules/$module" \
				OPT="${CFLAGS:--O2 -pipe} ${CPPFLAGS:-}" \
				prefix=/usr \
				libexecdir=/usr/lib \
				sysconfdir=/etc/openldap
		done
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			cd "openldap-$VER"
			for dir in clients servers doc/man/man1 doc/man/man5 doc/man/man8; do
				make -C "$dir" DESTDIR="$ROOT" install STRIP_OPTS=
			done

			for module in $EXTRA_MODULES; do
				make -C "contrib/slapd-modules/$module" \
					prefix=/usr \
					libexecdir=/usr/lib \
					sysconfdir=/etc/openldap \
					DESTDIR="$ROOT" install
				# passwd/* have no man page
				name="$(basename "$module")"
				if [ -f "contrib/slapd-modules/$module/slapo-$name.5" ]; then
					install -m644 -t "$ROOT/usr/share/man/man5" "contrib/slapd-modules/$module/slapo-$name.5"
				fi
			done

			# Belongs to the libs sub-package
			rm "$ROOT/usr/share/man/man5/ldap.conf.5"

			# systemd-tmpfiles creates this directory
			rm -r "$ROOT/run"

			# Duplicate configuration files
			rm "$ROOT"/etc/openldap/*.default

			# Libtool archives of the modules are not needed
			find "$ROOT/usr/lib" -name '*.la' -delete

			ln -s ../lib/slapd "$ROOT/usr/bin/slapd"

			# Ownership root:ldap is applied by the tmpfiles rules (the ldap
			# group only exists on the target system).
			chmod 640 "$ROOT/etc/openldap/slapd.conf" "$ROOT/etc/openldap/slapd.ldif"

			install -Dm644 "$PKGLUADIR/files/openldap.tmpfiles" "$ROOT/usr/lib/tmpfiles.d/openldap.conf"
			install -Dm644 "$PKGLUADIR/files/openldap.sysusers" "$ROOT/usr/lib/sysusers.d/openldap.conf"
		]],
			opts
		)
	elseif sub == "libs" then
		cmd(
			[[
			cd "openldap-$VER"
			for dir in include libraries doc/man/man3; do
				make -C "$dir" DESTDIR="$ROOT" install
			done
			install -Dm644 -t "$ROOT/usr/share/man/man5" doc/man/man5/ldap.conf.5

			# Duplicate configuration files
			rm "$ROOT"/etc/openldap/*.default

			find "$ROOT/usr/lib" -name '*.la' -delete
		]],
			opts
		)
	end

	zlicense("openldap-" .. version .. "/LICENSE")
	zlicense("openldap-" .. version .. "/COPYRIGHT")
end

local version = ZOI.VERSION or "2.1.28"
local sha512 =
	"db15af9079758a9f385457a79390c8a7cd7ea666573dace8bf4fb01bb4b49037538d67285727d6a70ad799d2e2318f265c9372e2427de9371d626a1959dd6f78"
-- Release signing key (Quanah Gibson-Mount), matches Arch's validpgpkeys.
local signing_key = "DEA1999F0CDB1AAEBA001E0DBEE3E3B4D2F06546"

-- Like Arch (libsasl + cyrus-sasl{,-gssapi,-ldap,-sql}), the library and the
-- self-contained mechanisms live in `libs`, so that openldap's client
-- library can use SASL without pulling in krb5/openldap themselves. `main`
-- carries saslauthd and the GSSAPI, LDAPDB and SQL (SQLite only) plugins.
metadata({
	name = "cyrus-sasl",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Cyrus Simple Authentication Service Layer (SASL) library",
	website = "https://www.cyrusimap.org/sasl/",
	license = "BSD-3-Clause-Attribution",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Carnegie Mellon University and the Cyrus project",
		website = "https://github.com/cyrusimap/cyrus-sasl",
	},
	bins = {
		"pluginviewer",
		"saslauthd",
		"sasldblistusers2",
		"saslpasswd2",
		"testsaslauthd",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "libs" },
	main_subs = { "main" },
	backup = {
		"${usrroot}/etc/conf.d/saslauthd",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:autoconf",
					"pacman:automake",
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gdbm",
					"pacman:krb5",
					"pacman:libldap",
					"pacman:libtool",
					"pacman:libxcrypt",
					"pacman:make",
					"pacman:openssl",
					"pacman:pam",
					"pacman:patch",
					"pacman:pkgconf",
					"pacman:sqlite",
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
					"zoi:@core/cyrus-sasl:libs",
					"zoi:@core/gdbm",
					"zoi:@core/glibc",
					"zoi:@core/krb5",
					"zoi:@core/libxcrypt",
					"zoi:@core/openldap:libs",
					"zoi:@core/openssl",
					"zoi:@core/pam",
					"zoi:@core/sqlite",
				},
			},
			libs = {
				required = {
					"zoi:@core/gdbm",
					"zoi:@core/glibc",
					"zoi:@core/openssl",
				},
			},
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "cyrus-sasl-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "cyrus-sasl-$VER.tar.gz"
		fetch "cyrus-sasl-$VER.tar.gz.sig"
		echo "$SHA512  cyrus-sasl-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	-- Upstream fixes Arch cherry-picks onto 2.1.28 (the CVE-2022-24407 fix
	-- Arch also picks is already in the release tarball). 0001 and 0007
	-- change configure.ac, so the build system is regenerated.
	cmd(
		[[
		tar -xf "cyrus-sasl-$VER.tar.gz"
		cd "cyrus-sasl-$VER"
		for p in "$PKGLUADIR"/patches/0*.patch; do
			patch -Np1 -i "$p"
		done
		autoreconf -fiv
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "cyrus-sasl-$VER"
		./configure \
			--prefix=/usr \
			--disable-krb4 \
			--disable-macos-framework \
			--disable-otp \
			--disable-passdss \
			--disable-srp \
			--disable-srp-setpass \
			--disable-static \
			--enable-alwaystrue \
			--enable-anon \
			--enable-auth-sasldb \
			--enable-checkapop \
			--enable-cram \
			--enable-digest \
			--enable-gssapi \
			--enable-ldapdb \
			--enable-login \
			--enable-ntlm \
			--enable-plain \
			--enable-shared \
			--enable-sql \
			--infodir=/usr/share/info \
			--mandir=/usr/share/man \
			--sbindir=/usr/bin \
			--sysconfdir=/etc \
			--with-dblib=gdbm \
			--with-devrandom=/dev/urandom \
			--with-configdir=/etc/sasl2:/etc/sasl:/usr/lib/sasl2 \
			--with-ldap \
			--without-mysql \
			--with-pam \
			--without-pgsql \
			--with-saslauthd=/run/saslauthd \
			--with-sqlite3=/usr/lib
		# Prevent excessive overlinking by libtool
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			cd "cyrus-sasl-$VER"
			make DESTDIR="$ROOT" install -C saslauthd
			make DESTDIR="$ROOT" install-data-local -C saslauthd

			install -vdm755 "$ROOT/usr/lib/sasl2"
			cp -av plugins/.libs/libgs2.so* plugins/.libs/libgssapiv2.so* \
				plugins/.libs/libldapdb.so* plugins/.libs/libsql.so* "$ROOT/usr/lib/sasl2/"

			install -vDm644 "$PKGLUADIR/files/saslauthd.conf.d" "$ROOT/etc/conf.d/saslauthd"
			install -vDm644 "$PKGLUADIR/files/saslauthd.service" -t "$ROOT/usr/lib/systemd/system/"
		]],
			opts
		)
	elseif sub == "libs" then
		cmd(
			[[
			cd "cyrus-sasl-$VER"
			make DESTDIR="$ROOT" install-pkgconfigDATA
			for target in include lib sasldb plugins utils; do
				make DESTDIR="$ROOT" install -C "$target"
			done
			# These plugins belong to the main sub-package
			rm -fv "$ROOT"/usr/lib/sasl2/lib{gs2,gssapiv2,ldapdb,sql}.so*
			# Libtool archives are not shipped (as with Arch's !libtool).
			find "$ROOT/usr/lib" -name '*.la' -delete
		]],
			opts
		)
	end

	zlicense("cyrus-sasl-" .. version .. "/COPYING")
end

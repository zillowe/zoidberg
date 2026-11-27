local version = ZOI.VERSION or "5.44.0"
local baseversion = string.match(version, "^(%d+%.%d+)") or version
-- Perl releases are not signed. This hash is taken from Gentoo's Manifest;
-- CPAN publishes a sha256 next to the tarball (perl-<version>.tar.xz.sha256.txt)
-- that can be used to cross-check it.
local sha512 = "734d00d00678add11544e8f483bf953e61ae391aa6a2bba61ec4e7727275e243cc411525d30e6a73f70ccc0603ebe85bc0c6dd69b0106a6162e21a4595d11075"

metadata({
	name = "perl",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "A highly capable, feature-rich programming language",
	website = "https://www.perl.org",
	license = "Artistic-1.0-Perl OR GPL-1.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Perl Foundation",
		website = "https://www.perl.org",
	},
	bins = { "perl" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	quiet = { "build" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:gcc",
					"pacman:libxcrypt",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libxcrypt",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, BASEVER = baseversion, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.cpan.org/src/5.0" \
				"https://cpan.metacpan.org/src/5.0"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "perl-$VER.tar.xz"
		echo "$SHA512  perl-$VER.tar.xz" | sha512sum -c -
		tar -xf "perl-$VER.tar.xz"
		cd "perl-$VER"

		# Fix regex super-linear cache countdown before the 64-bit cleanup:
		# https://github.com/Perl/perl5/commit/568e6fd238867bb9e99fa3f47cba3169009239e0
		patch -Np1 -i "$PKGLUADIR/patches/0001-regex-super-linear-cache-make-countdown-unsigned.patch"
		# Fix potential regex super-linear cache OOB access on very large matches:
		# https://github.com/Perl/perl5/commit/54cf3d44cbbedd17d774e9a37921963e8fd5d0cb
		patch -Np1 -i "$PKGLUADIR/patches/0002-regex-make-superlinear-cache-64-bit-clean.patch"

		# Reproducible patchlevel_date
		if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
			touch -h -d "@$SOURCE_DATE_EPOCH" patchlevel.h
		fi
	]],
		opts
	)
end

function build()
	-- Parlex ships no gdbm or Berkeley DB, so their extensions are skipped
	-- instead of linking whatever the build host provides.
	cmd(
		[[
		cd "perl-$VER"

		# Reproducible build overrides are only fully effective when loaded from file
		cp "$PKGLUADIR/files/config.over" .

		export TZ=UTC
		# The man directories are set explicitly: -des otherwise looks for one
		# on the build machine, and the minimal CI image has none, so every
		# man page was installed into / as <name>.0.
		./Configure -des -Dusethreads -Duseshrplib \
			-Doptimize="${CFLAGS:--O2 -pipe}" \
			-Dprefix=/usr -Dvendorprefix=/usr \
			-Dprivlib=/usr/share/perl5/core_perl \
			-Darchlib="/usr/lib/perl5/$BASEVER/core_perl" \
			-Dsitelib=/usr/share/perl5/site_perl \
			-Dsitearch="/usr/lib/perl5/$BASEVER/site_perl" \
			-Dvendorlib=/usr/share/perl5/vendor_perl \
			-Dvendorarch="/usr/lib/perl5/$BASEVER/vendor_perl" \
			-Dscriptdir=/usr/bin/core_perl \
			-Dsitescript=/usr/bin/site_perl \
			-Dvendorscript=/usr/bin/vendor_perl \
			-Dinc_version_list=none \
			-Dman1dir=/usr/share/man/man1 -Dman3dir=/usr/share/man/man3 \
			-Dsiteman1dir=/usr/share/man/man1 -Dsiteman3dir=/usr/share/man/man3 \
			-Dvendorman1dir=/usr/share/man/man1 -Dvendorman3dir=/usr/share/man/man3 \
			-Dman1ext=1perl -Dman3ext=3perl \
			-Dlddlflags="-shared ${LDFLAGS:-}" -Dldflags="${LDFLAGS:-}" \
			-Dnoextensions='DB_File GDBM_File NDBM_File ODBM_File'
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "perl-$VER" DESTDIR="$ROOT" install

		# Change man page extensions for site and vendor module builds.
		# Set no mail address since bug reports should go to the bug tracker
		# and not someone's email.
		sed -e '/^man1ext=/ s/1perl/1p/' -e '/^man3ext=/ s/3perl/3pm/' \
			-e "/^cf_email=/ s/'.*'/''/" \
			-e "/^perladmin=/ s/'.*'/''/" \
			-i "$ROOT/usr/lib/perl5/$BASEVER/core_perl/Config_heavy.pl"

		# Set CPAN default config to use the site directories
		sed -e '/(makepl_arg =>/   s/""/"INSTALLDIRS=site"/' \
			-e '/(mbuildpl_arg =>/ s/""/"installdirs=site"/' \
			-i "$ROOT/usr/share/perl5/core_perl/CPAN/FirstTime.pm"

		# Profile scripts adding the perl script directories to PATH
		install -Dm644 "$PKGLUADIR/files/perlbin.sh" "$ROOT/etc/profile.d/perlbin.sh"
		install -Dm644 "$PKGLUADIR/files/perlbin.csh" "$ROOT/etc/profile.d/perlbin.csh"
		install -Dm755 "$PKGLUADIR/files/perlbin.fish" "$ROOT/usr/share/fish/vendor_conf.d/perlbin.fish"

		# Create the dirs so new installs already have them in PATH once
		# they install their first perl program
		install -dm755 "$ROOT/usr/bin/vendor_perl"
		install -dm755 "$ROOT/usr/bin/site_perl"

		rm -f "$ROOT/usr/bin/perl$VER"
	]],
		opts
	)

	-- Perl is dual-licensed: the Artistic License or the GPL (version 1 or later).
	zlicense("perl-" .. version .. "/Artistic")
	zlicense("perl-" .. version .. "/Copying")
end

function test()
	cmd([[
		/usr/bin/perl -v || perl -v
	]])
end

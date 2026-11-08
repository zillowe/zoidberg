local version = ZOI.VERSION or "5.44.0"
local baseversion = string.match(version, "^(%d+%.%d+)") or version

metadata({
	name = "perl",
	repo = "core",
	version = version,
	revision = "1",
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
					"pacman:gcc",
					"pacman:git",
					"pacman:libxcrypt",
					"pacman:make",
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

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "BASEVER='" .. baseversion .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d perl ]; then
			git clone --depth 1 --branch "v$VER" https://github.com/Perl/perl5.git perl
			cd perl
			git config user.email "contact@zillowe.qzz.io"
			git config user.name "Zillowe Foundation"

			# Fix regex super-linear cache countdown before the 64-bit cleanup:
			# https://github.com/Perl/perl5/commit/568e6fd238867bb9e99fa3f47cba3169009239e0
			# Fix potential regex super-linear cache OOB access on very large matches:
			# https://github.com/Perl/perl5/commit/54cf3d44cbbedd17d774e9a37921963e8fd5d0cb
			for c in 568e6fd238867bb9e99fa3f47cba3169009239e0 54cf3d44cbbedd17d774e9a37921963e8fd5d0cb; do
				git fetch --depth 2 origin "$c"
				git cherry-pick -n "$c"
			done

			# Reproducible patchlevel_date
			if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
				touch -h -d "@$SOURCE_DATE_EPOCH" patchlevel.h
			fi
		fi
	]])
end

function build()
	-- Parlex ships no gdbm or Berkeley DB, so their extensions are skipped
	-- instead of linking whatever the build host provides.
	sh([[
		cd perl

		# Reproducible build overrides are only fully effective when loaded from file
		cp "$PKGLUADIR/config.over" .

		export TZ=UTC
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
			-Dman1ext=1perl -Dman3ext=3perl \
			-Dlddlflags="-shared ${LDFLAGS:-}" -Dldflags="${LDFLAGS:-}" \
			-Dnoextensions='DB_File GDBM_File NDBM_File ODBM_File'
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C perl DESTDIR="$ROOT" install

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
		install -Dm644 "$PKGLUADIR/perlbin.sh" "$ROOT/etc/profile.d/perlbin.sh"
		install -Dm644 "$PKGLUADIR/perlbin.csh" "$ROOT/etc/profile.d/perlbin.csh"
		install -Dm755 "$PKGLUADIR/perlbin.fish" "$ROOT/usr/share/fish/vendor_conf.d/perlbin.fish"

		# Create the dirs so new installs already have them in PATH once
		# they install their first perl program
		install -dm755 "$ROOT/usr/bin/vendor_perl"
		install -dm755 "$ROOT/usr/bin/site_perl"

		rm -f "$ROOT/usr/bin/perl$VER"
	]])
end

function test()
	cmd([[
		/usr/bin/perl -v || perl -v
	]])
end

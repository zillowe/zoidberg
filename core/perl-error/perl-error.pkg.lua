local version = ZOI.VERSION or "0.17031"
local sha512 = "02db3ac45d099d182d1c3dfd83db64df4a582511128e1141315a052fdc5f2c626c883fc3c0567b6ed97c2fe5aa4a2a71b5086b3242c104589d3de938f3d70359"
-- CPAN releases are not signed. The hash matches Arch Linux's sha512sums
-- for the same CPAN tarball.

metadata({
	name = "perl-error",
	repo = "core",
	version = version,
	revision = "1",
	description = "Perl/CPAN Error module - Error/exception handling in an OO-ish way",
	website = "https://metacpan.org/release/Error",
	license = "Artistic-1.0-Perl OR GPL-1.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Shlomi Fish",
		website = "https://metacpan.org/release/Error",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:make",
					"pacman:perl",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/perl",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = {
		VER = version,
		SHA512 = sha512,
		CPAN_PATH = "S/SH/SHLOMIF",
		PERL_MM_USE_DEFAULT = "1",
		PERL_AUTOINSTALL = "--skipdeps",
	},
}

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://cpan.metacpan.org/authors/id/$CPAN_PATH" \
				"https://www.cpan.org/authors/id/$CPAN_PATH"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "Error-$VER.tar.gz"
		echo "$SHA512  Error-$VER.tar.gz" | sha512sum -c -
		tar -xf "Error-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "Error-$VER"
		perl Makefile.PL INSTALLDIRS=vendor
		make
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "Error-$VER"
		make DESTDIR="$ROOT" install
		# Build-host bookkeeping files that must not be shipped
		find "$ROOT" \( -name perllocal.pod -o -name .packlist \) -delete
		find "$ROOT" -depth -type d -empty -delete
	]],
		opts
	)
	zlicense("Error-" .. version .. "/LICENSE")
	zdoc("Error-" .. version .. "/README")
end

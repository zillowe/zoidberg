local version = ZOI.VERSION or "2.22"
local sha512 = "5bab5af263cbbf1483ebb210086d101ac1d4517dcb30aaba8124a2cc71e3667c32ca19fc2bc169cd646af1a6bb4f7afee84535d1a93668658e1d74f4dc70c3e0"
-- CPAN releases are not signed. The hash matches Arch Linux's sha512sums
-- for the same CPAN tarball.

metadata({
	name = "perl-mailtools",
	repo = "core",
	version = version,
	revision = "1",
	description = "Various e-mail related modules",
	website = "https://metacpan.org/release/MailTools",
	license = "Artistic-1.0-Perl OR GPL-1.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Mark Overmeer",
		website = "https://metacpan.org/release/MailTools",
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
			"zoi:@core/perl-timedate",
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
		CPAN_PATH = "M/MA/MARKOV",
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
		fetch "MailTools-$VER.tar.gz"
		echo "$SHA512  MailTools-$VER.tar.gz" | sha512sum -c -
		tar -xf "MailTools-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "MailTools-$VER"
		perl Makefile.PL INSTALLDIRS=vendor
		make
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "MailTools-$VER"
		make DESTDIR="$ROOT" install
		# Build-host bookkeeping files that must not be shipped
		find "$ROOT" \( -name perllocal.pod -o -name .packlist \) -delete
		find "$ROOT" -depth -type d -empty -delete
	]],
		opts
	)
	-- Upstream ships no license file; README.md only says "licensed as perl
	-- itself". LICENSE.Perl is the standard Perl 5 terms text (as shipped by
	-- other CPAN distributions) with the MailTools copyright line.
	zlicense("${pkgluadir}/files/LICENSE.Perl", "LICENSE")
	zdoc("MailTools-" .. version .. "/README.md")
end

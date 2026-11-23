local version = ZOI.VERSION or "2.35"
local sha512 = "8c508a958e7ce98638ba9d16606b9b769da822ee61e7b8d8143e0ff5a45edb6b60710e826046510c966ecf5d3bf28f003dcf38a0b94f7319ba46c80c6e889f87"
-- CPAN releases are not signed. The hash matches Arch Linux's sha512sums
-- for the same CPAN tarball.

metadata({
	name = "perl-timedate",
	repo = "core",
	version = version,
	revision = "1",
	description = "Date formating subroutines",
	website = "https://metacpan.org/release/TimeDate",
	license = "Artistic-1.0-Perl OR GPL-1.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Graham Barr",
		website = "https://metacpan.org/release/TimeDate",
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
		CPAN_PATH = "A/AT/ATOOMIC",
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
		fetch "TimeDate-$VER.tar.gz"
		echo "$SHA512  TimeDate-$VER.tar.gz" | sha512sum -c -
		tar -xf "TimeDate-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "TimeDate-$VER"
		perl Makefile.PL INSTALLDIRS=vendor
		make
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "TimeDate-$VER"
		make DESTDIR="$ROOT" install
		# Build-host bookkeeping files that must not be shipped
		find "$ROOT" \( -name perllocal.pod -o -name .packlist \) -delete
		find "$ROOT" -depth -type d -empty -delete
	]],
		opts
	)
	zlicense("TimeDate-" .. version .. "/LICENSE")
	zdoc("TimeDate-" .. version .. "/README")
end

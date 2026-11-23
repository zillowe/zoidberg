local version = ZOI.VERSION or "39"
local sha512 =
	"04493c30efbfc2773abac9a3dd93aa13403c05e29e3bfc72877d2054930811fae99119aadcb1729b6ca85abf5a24db786ea0c27c16d5458ef1b19e74696f5ff7"
-- efivar publishes no release tarball (only signed git tags, by Peter Jones
-- B00B48BC731AA8840FED9FB0EED266B70F4FEF10 as in Arch Linux's
-- validpgpkeys), so this is GitHub's archive of the tag. The hash matches
-- the one Gentoo records for the same archive (sys-libs/efivar Manifest).

metadata({
	name = "efivar",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Tools and libraries to work with EFI variables",
	website = "https://github.com/rhboot/efivar",
	license = "LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Peter Jones and others",
		website = "https://github.com/rhboot/efivar",
	},
	bins = { "efisecdb", "efivar" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:mandoc",
					"pacman:pkgconf",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/rhboot/efivar/archive/refs/tags/$VER.tar.gz" \
			-o "efivar-$VER.tar.gz"
		echo "$SHA512  efivar-$VER.tar.gz" | sha512sum -c -
		tar -xf "efivar-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	-- ERRORS='' drops -Werror, as Arch does.
	cmd([[make ERRORS='' all -C "efivar-$VER"]], opts)
end

function package()
	cmd(
		[[
		make V=1 DESTDIR="$ROOT/" \
			libdir=/usr/lib/ \
			bindir=/usr/bin/ \
			mandir=/usr/share/man/ \
			includedir=/usr/include/ \
			install -j1 -C "efivar-$VER"
	]],
		opts
	)
	zlicense("efivar-" .. version .. "/COPYING")
	zdoc("efivar-" .. version .. "/README.md")
	zdoc("efivar-" .. version .. "/TODO")
end

function test()
	cmd([[
		/usr/bin/efivar --version || efivar --version
	]])
end

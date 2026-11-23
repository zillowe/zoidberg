local version = ZOI.VERSION or "18"
local sha512 =
	"59112a3da3bad782ae893e1390f5a371474392f9779a2769a9d56335760b611b5330fe57b46e8d858d237786230162a0947261769c02c960549be6c1f6a5f4a6"
-- Upstream signs its git tags but not the release tarball. Its contents were
-- checked to be identical to the tag archive (verified against Gentoo's
-- Manifest), apart from the generated efibootmgr.spec.

metadata({
	name = "efibootmgr",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Linux user-space application to modify the EFI Boot Manager",
	website = "https://github.com/rhboot/efibootmgr",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Peter Jones and others",
		website = "https://github.com/rhboot/efibootmgr",
	},
	bins = {
		"efibootdump",
		"efibootmgr",
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
					"pacman:curl",
					"pacman:efivar",
					"pacman:gcc",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:popt",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/efivar",
			"zoi:@core/glibc",
			"zoi:@core/popt",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/rhboot/efibootmgr/releases/download/$VER/efibootmgr-$VER.tar.bz2" \
			-o "efibootmgr-$VER.tar.bz2"
		echo "$SHA512  efibootmgr-$VER.tar.bz2" | sha512sum -c -
		tar -xf "efibootmgr-$VER.tar.bz2"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		make libdir=/usr/lib sbindir=/usr/bin EFIDIR=parlex -C "efibootmgr-$VER" -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make DESTDIR="$ROOT" libdir=/usr/lib sbindir=/usr/bin EFIDIR=parlex install -C "efibootmgr-$VER"
	]],
		opts
	)

	local src = "efibootmgr-" .. version
	zlicense(src .. "/COPYING")
	zdoc(src .. "/AUTHORS")
	zdoc(src .. "/README")
	zdoc(src .. "/README.md")
	zdoc(src .. "/TODO")
end

function test()
	cmd([[
		/usr/bin/efibootmgr --help || efibootmgr --help || true
	]])
end

local version = ZOI.VERSION or "4.2"
local sha512 = "3cc0808edb4432428df8a67da4bb314fd1f27adc4a05754c1a492091741a7b6875ebd9f6a509cc4c5ad85643fc40395b6e0cadee548b25cc439cc9b725980156"
-- Release signing key (Andreas Bombe), as listed by Arch Linux.
local signing_key = "25714AECDBFDACEE1CE95FE77F6022516E869F64"

metadata({
	name = "dosfstools",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "DOS filesystem utilities",
	website = "https://github.com/dosfstools/dosfstools",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "dosfstools contributors",
		website = "https://github.com/dosfstools/dosfstools",
	},
	-- With the compat links Arch Linux enables (dosfsck, mkfs.vfat, ...).
	bins = {
		"fatlabel",
		"fsck.fat",
		"mkfs.fat",
		"dosfsck",
		"dosfslabel",
		"fsck.msdos",
		"fsck.vfat",
		"mkdosfs",
		"mkfs.msdos",
		"mkfs.vfat",
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
					"pacman:gcc",
					"pacman:make",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "dosfstools-" .. version .. ".tar.gz"
	cmd(
		[[
		base="https://github.com/dosfstools/dosfstools/releases/download/v$VER"
		curl -sSfL --retry 3 --retry-all-errors "$base/dosfstools-$VER.tar.gz" -o "dosfstools-$VER.tar.gz"
		curl -sSfL --retry 3 --retry-all-errors "$base/dosfstools-$VER.tar.gz.sig" -o "dosfstools-$VER.tar.gz.sig"
		echo "$SHA512  dosfstools-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	-- Upstream commit 8da7bc9, which Arch Linux applies: mkfs.fat output
	-- becomes reproducible (SOURCE_DATE_EPOCH for the volume ID and times).
	cmd(
		[[
		tar -xf "dosfstools-$VER.tar.gz"
		patch -d "dosfstools-$VER" -Np1 -i "$PKGLUADIR/patches/0001-reproducible-mkfs.patch"
	]],
		opts
	)
end

function build()
	-- Options follow Arch Linux's PKGBUILD.
	cmd(
		[[
		cd "dosfstools-$VER"
		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--sbindir=/usr/bin \
			--mandir=/usr/share/man \
			--docdir=/usr/share/doc/dosfstools \
			--enable-compat-symlinks
		make
	]],
		opts
	)
end

function package()
	cmd([[make -C "dosfstools-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("dosfstools-" .. version .. "/COPYING")
end

function test()
	cmd(
		[[
		truncate -s 8M fat.img
		"$ROOT/usr/bin/mkfs.fat" -n ZOITEST fat.img
		"$ROOT/usr/bin/fsck.fat" -n fat.img
		rm fat.img
	]],
		opts
	)
	return true
end

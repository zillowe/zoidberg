local version = ZOI.VERSION or "2.10.0"
local sha512 = "1b7f55f0a1b34d9b6b4237a1ff3e10eedf4bdebe50e906a7acdea48f85b3c455e72737127491a0c494388b999797aa65411b20b44c3f5612fdeee4d8289f937c"
-- Release signing key (Alexey Gladkov), from keyserver.ubuntu.com.
local signing_key = "7F2A3D07298149A0793C9A4EA45ABA544CFFD434"

metadata({
	name = "kbd",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Keytable files and keyboard utilities",
	website = "https://kbd-project.org",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Alexey Gladkov",
		website = "https://kbd-project.org",
	},
	bins = {
		"chvt",
		"clrunimap",
		"deallocvt",
		"dumpkeys",
		"fgconsole",
		"getkeycodes",
		"getunimap",
		"kbd_mode",
		"kbdinfo",
		"kbdrate",
		"loadkeys",
		"loadunimap",
		"mapscrn",
		"openvt",
		"outpsfheader",
		"psfaddtable",
		"psfgettable",
		"psfstriptable",
		"psfxtable",
		"resizecons",
		"screendump",
		"setfont",
		"setkeycodes",
		"setleds",
		"setlogcons",
		"setmetamode",
		"setpalette",
		"setvesablank",
		"setvtrgb",
		"showconsolefont",
		"showkey",
		"spawn_console",
		"spawn_login",
		"unicode_start",
		"unicode_stop",
		"vlock",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/pam.d/vlock",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					-- Headers for kbd's dlopen()ed decompressors. Configure
					-- enables bzip2 whenever libbz2 links, so bzlib.h must exist.
					"pacman:bzip2",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gzip",
					"pacman:make",
					"pacman:pam",
					"pacman:pkgconf",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			-- Keymaps and fonts are installed gzipped; without zlib, kbd
			-- decompresses them by running `gzip -d -c`.
			"zoi:@core/gzip",
			"zoi:@core/pam",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "kbd-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/linux/utils/kbd" \
				"https://www.kernel.org/pub/linux/utils/kbd" \
				"https://mirrors.kernel.org/pub/linux/utils/kbd"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "kbd-$VER.tar.xz"
		fetch "kbd-$VER.tar.sign"
		echo "$SHA512  kbd-$VER.tar.xz" | sha512sum -c -
		# kernel.org signs the uncompressed tar.
		xz -dk "kbd-$VER.tar.xz"
	]],
		opts
	)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "kbd-$VER.tar.xz"
		cd "kbd-$VER"
		# Rename keymaps that share a name with another one: loadkeys loads the
		# first match for a bare name (same renames as Arch, FS#13837).
		mv data/keymaps/i386/qwertz/cz{,-qwertz}.map
		mv data/keymaps/i386/olpc/es{,-olpc}.map
		mv data/keymaps/i386/olpc/pt{,-olpc}.map
		mv data/keymaps/i386/fgGIod/trf{,-fgGIod}.map
		mv data/keymaps/i386/colemak/{en-latin9,colemak}.map
		# euro2: AltGr+E gives the euro sign, not the generic currency sign.
		patch -Np1 -i "$PKGLUADIR/patches/fix-euro2.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "kbd-$VER"
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--datadir=/usr/share/kbd \
			--mandir=/usr/share/man \
			--enable-optional-progs \
			--disable-tests
		make -j"$(nproc)" KEYCODES_PROGS=yes RESIZECONS_PROGS=yes
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "kbd-$VER"
		make KEYCODES_PROGS=yes RESIZECONS_PROGS=yes DESTDIR="$ROOT" install
		# Plain pam_unix stack for vlock (as Arch) instead of upstream's file,
		# which has no session entry.
		install -Dm644 "$PKGLUADIR/files/vlock.pam" "$ROOT/etc/pam.d/vlock"
	]],
		opts
	)

	zlicense("kbd-" .. version .. "/COPYING")
end

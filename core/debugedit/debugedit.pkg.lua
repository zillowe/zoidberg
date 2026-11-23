local version = ZOI.VERSION or "5.4"
local sha512 =
	"a5813796779f7a09c4845b4d995296692d88ab8fe889c7c97b1f868dec4b6f9c426bcb18dd051a6f49e2275d553374103460c1b700e78c4db7dc7eafd4c55342"
-- Release signing key (Mark J. Wielaard), listed in Arch Linux's validpgpkeys.
local signing_key = "28FF4B30A88D5523A7E2CBA20376A15C6FFC11CD"

metadata({
	name = "debugedit",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Tool to mangle source locations in .debug files",
	website = "https://sourceware.org/debugedit/",
	license = "GPL-3.0-or-later AND GPL-2.0-or-later AND LGPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The debugedit developers",
		website = "https://sourceware.org/debugedit/",
	},
	bins = { "debugedit", "find-debuginfo", "sepdebugcrcfix" },
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:elfutils",
					"pacman:gcc",
					"pacman:help2man",
					"pacman:libtool",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
					"pacman:xxhash",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/cpio",
			"zoi:@core/elfutils",
			"zoi:@core/elfutils:libelf",
			"zoi:@core/glibc",
			"zoi:@core/xxhash",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "debugedit-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://mirrors.kernel.org/sourceware/debugedit/$VER" \
				"https://sourceware.org/ftp/debugedit/$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "debugedit-$VER.tar.xz"
		fetch "debugedit-$VER.tar.xz.sig"
		echo "$SHA512  debugedit-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	-- The patch turns configure's hard error on a missing dwz into a
	-- warning, so configure has to be regenerated.
	cmd(
		[[
		tar -xf "debugedit-$VER.tar.xz"
		cd "debugedit-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/remove-dwz.patch"
		autoreconf -fiv
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "debugedit-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "debugedit-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "debugedit-" .. version
	zlicense(src .. "/COPYING3")
	zlicense(src .. "/COPYING")
	zlicense(src .. "/COPYING.LIB")
end

function test()
	cmd([[
		/usr/bin/debugedit --version || debugedit --version
	]])
end

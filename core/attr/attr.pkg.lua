local version = ZOI.VERSION or "2.6.0"
local sha512 =
	"870d0c34fbaa7520aad058ecd6509fe8eddd17430781a16d1e80484d4947307a7c641f0449183cbac1da611a85f82c9bee2d2d7bff76170fc2195b123100d22e"
-- Release signing key (Andreas Gruenbacher), from upstream's keyring.
local signing_key = "259B3792B3D6D319212CC4DCD5BF9FEB0313653A"

metadata({
	name = "attr",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Extended attribute support library for ACL support",
	website = "https://savannah.nongnu.org/projects/attr",
	license = "LGPL-2.1-or-later AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The attr developers",
		website = "https://savannah.nongnu.org/projects/attr",
	},
	bins = { "attr", "getfattr", "setfattr" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/xattr.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:gcc",
					"pacman:gettext",
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

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "attr-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://download.savannah.nongnu.org/releases/attr" \
				"https://download-mirror.savannah.gnu.org/releases/attr"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "attr-$VER.tar.xz"
		fetch "attr-$VER.tar.xz.sig"
		echo "$SHA512  attr-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "attr-$VER.tar.xz"
		cd "attr-$VER"

		# Remove the nfs entries from /etc/xattr.conf
		# http://lists.gnu.org/archive/html/bug-coreutils/2019-03/msg00008.html
		sed -i '/nfs/d' xattr.conf
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "attr-$VER"
		./configure \
			--libdir=/usr/lib \
			--libexecdir=/usr/lib \
			--prefix=/usr \
			--sysconfdir=/etc
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "attr-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("attr-" .. version .. "/doc/COPYING")
	zlicense("attr-" .. version .. "/doc/COPYING.LGPL")
end

function test()
	cmd([[
		/usr/bin/getfattr --version || getfattr --version
	]])
end

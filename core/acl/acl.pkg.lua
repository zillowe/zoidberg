local version = ZOI.VERSION or "2.4.0"

metadata({
	name = "acl",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Access control list utilities, libraries and headers",
	website = "https://savannah.nongnu.org/projects/acl",
	license = "LGPL-2.1-or-later AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The acl developers",
		website = "https://savannah.nongnu.org/projects/acl",
	},
	bins = { "chacl", "getfacl", "setfacl" },
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
					"pacman:attr",
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

local sha512 = "d81737abe566310a1a9de207cbf204449bd55ce5b549c6613e5f474a6592e03fac7c80826ddce7543a954d32b99d8b5e25c5e3dcc5fab7b1b381627cc1240de6"
-- Release signing key (Andreas Gruenbacher), from upstream's keyring.
local signing_key = "259B3792B3D6D319212CC4DCD5BF9FEB0313653A"

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	local tarball = "acl-" .. version .. ".tar.xz"
	sh([[
		fetch() {
			for base in \
				"https://download.savannah.nongnu.org/releases/acl" \
				"https://download-mirror.savannah.gnu.org/releases/acl"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "acl-$VER.tar.xz"
		fetch "acl-$VER.tar.xz.sig"
		echo "$SHA512  acl-$VER.tar.xz" | sha512sum -c -
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "acl-$VER.tar.xz"]])
end

function build()
	sh([[
		cd "acl-$VER"
		./configure \
			--libdir=/usr/lib \
			--libexecdir=/usr/lib \
			--prefix=/usr
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "acl-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/getfacl --version || getfacl --version
	]])
end

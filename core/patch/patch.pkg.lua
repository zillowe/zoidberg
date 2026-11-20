local version = ZOI.VERSION or "2.8.1"

metadata({
	name = "patch",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "A utility to apply patch files to original sources",
	website = "https://www.gnu.org/software/patch/",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "patch" },
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
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:attr",
					"pacman:ed",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:make",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/attr",
			"zoi:@core/glibc",
		},
	},
})

local sha512 = "344cad0f3a19a651c8f0188c89402018c65406b106adecdfec52df4359046ca5d86a70ce8d7943f8c41deed79918291b0a86bfa57dcec2c0aa2b4bbca6edc698"
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
	local tarball = "patch-" .. version .. ".tar.xz"
	sh([[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/patch" \
				"https://mirrors.kernel.org/gnu/patch" \
				"https://ftp.gnu.org/gnu/patch"; do
				curl -sSfL --retry 3 "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "patch-$VER.tar.xz"
		fetch "patch-$VER.tar.xz.sig"
		echo "$SHA512  patch-$VER.tar.xz" | sha512sum -c -
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "patch-$VER.tar.xz"]])
end

function build()
	sh([[
		cd "patch-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "patch-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/patch --version || patch --version
	]])
end

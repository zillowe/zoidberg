local version = ZOI.VERSION or "2.8.1"
local sha512 = "344cad0f3a19a651c8f0188c89402018c65406b106adecdfec52df4359046ca5d86a70ce8d7943f8c41deed79918291b0a86bfa57dcec2c0aa2b4bbca6edc698"
-- Release signing key (Andreas Gruenbacher), from upstream's keyring.
local signing_key = "259B3792B3D6D319212CC4DCD5BF9FEB0313653A"

metadata({
	name = "patch",
	repo = "core",
	version = version,
	revision = "5",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "patch-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/patch" \
				"https://mirrors.kernel.org/gnu/patch" \
				"https://ftp.gnu.org/gnu/patch"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "patch-$VER.tar.xz"
		fetch "patch-$VER.tar.xz.sig"
		echo "$SHA512  patch-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "patch-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "patch-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "patch-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("patch-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/patch --version || patch --version
	]])
end

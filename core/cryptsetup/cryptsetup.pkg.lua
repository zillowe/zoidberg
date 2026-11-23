local version = ZOI.VERSION or "2.8.8"
local sha512 =
	"cec6499d90540f6b7b118f12bd4f150d06d18465ca93e38d792e8e3f3c39882bb9f33c893ed92974a1dd52df4c59629c002cae045b0bfbb44ca468d346e8383f"
-- Release signing key (Milan Broz), from upstream's published keys.
local signing_key = "2A2918243FDE46648D0686F9D9B0577BD93E98FC"

metadata({
	name = "cryptsetup",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Userspace setup tool for transparent encryption of block devices using dm-crypt",
	website = "https://gitlab.com/cryptsetup/cryptsetup",
	license = "GPL-2.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Milan Broz",
		website = "https://gitlab.com/cryptsetup/cryptsetup",
	},
	bins = { "cryptsetup", "veritysetup", "integritysetup" },
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
					"pacman:asciidoctor",
					"pacman:base-devel",
					"pacman:curl",
					"pacman:device-mapper",
					"pacman:gcc",
					"pacman:json-c",
					"pacman:make",
					"pacman:openssl",
					"pacman:pkgconf",
					"pacman:popt",
					"pacman:util-linux",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/device-mapper",
			"zoi:@core/glibc",
			"zoi:@core/json-c",
			"zoi:@core/openssl",
			"zoi:@core/popt",
			"zoi:@core/util-linux:libs",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "cryptsetup-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/linux/utils/cryptsetup/v2.8" \
				"https://www.kernel.org/pub/linux/utils/cryptsetup/v2.8"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "cryptsetup-$VER.tar.xz"
		fetch "cryptsetup-$VER.tar.sign"
		echo "$SHA512  cryptsetup-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	cmd([[xz -dk "cryptsetup-$VER.tar.xz"]], opts)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "cryptsetup-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "cryptsetup-$VER"
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--disable-static \
			--disable-ssh-token \
			--disable-external-tokens
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "cryptsetup-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "cryptsetup-" .. version
	zlicense(src .. "/COPYING")
	for _, f in ipairs({
		"COPYING.GPL-2.0-or-later-WITH-cryptsetup-OpenSSL-exception",
		"COPYING.LGPL-2.1-or-later-WITH-cryptsetup-OpenSSL-exception",
		"COPYING.Apache-2.0",
		"COPYING.CC-BY-SA-4.0",
	}) do
		zlicense(src .. "/docs/licenses/" .. f)
	end
	zdoc(src .. "/README.licensing")
	zdoc(src .. "/FAQ.md")
	zdoc(src .. "/docs/Keyring.txt")
	zdoc(src .. "/docs/LUKS2-locking.txt")
end

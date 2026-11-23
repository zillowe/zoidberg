local version = ZOI.VERSION or "1.19.0"
local sha512 = "fc8a65ccc2119a020bc76f356fe0f7adb553ead0c4d28b7c6de008045b025e5a1c57ac6f3acb095ce42e15a9283c6e943cb9a6415c9d9433971528b592eea4f7"
-- Upstream signs releases (subkey 516B622918D15C478AB1EA3A5339A2BE82E07DEC of
-- key F4F3B91474D1EB29889BD0EF7E8403D5D673C366, Tatsuhiro Tsujikawa, Arch's
-- validpgpkeys), but the subkey is only bound with a SHA-1 signature, which
-- Zoi's verifier rejects. The signature was checked with gpg when this hash
-- was recorded, and the hash matches Gentoo's Manifest; the pinned hash is
-- the trust anchor.

metadata({
	name = "libnghttp3",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "HTTP/3 library written in C",
	website = "https://github.com/ngtcp2/nghttp3",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The ngtcp2 project",
		website = "https://nghttp2.org/nghttp3/",
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:tar",
					"pacman:xz",
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
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/ngtcp2/nghttp3/releases/download/v$VER/nghttp3-$VER.tar.xz" \
			-o "nghttp3-$VER.tar.xz"
		echo "$SHA512  nghttp3-$VER.tar.xz" | sha512sum -c -
		tar -xf "nghttp3-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "nghttp3-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "nghttp3-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("nghttp3-" .. version .. "/COPYING")
end

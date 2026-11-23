local version = ZOI.VERSION or "2.15.1"
local sha512 = "0ce117ff1108622ce47a671ee27e0362834bcd9665d408f455fc3c6b68816a51d9fffa5e23faf8cefcdb1a9d9be89ad08076afd02530f665d6fa622b6d9f153d"
-- Upstream signs releases (key B5D6953E6D5059ED7ADA0F2FD3657D24D058434C,
-- Petri Lehtinen, Arch's validpgpkeys), but the key is only bound with SHA-1
-- self-signatures, which Zoi's verifier rejects. The signature was checked
-- with gpg when this hash was recorded, and the hash matches Gentoo's
-- Manifest; the pinned hash is the trust anchor.

metadata({
	name = "jansson",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "C library for encoding, decoding and manipulating JSON data",
	website = "https://www.digip.org/jansson/",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Petri Lehtinen",
		website = "https://www.digip.org/jansson/",
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
					"pacman:bzip2",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:tar",
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
			"https://github.com/akheron/jansson/releases/download/v$VER/jansson-$VER.tar.bz2" \
			-o "jansson-$VER.tar.bz2"
		echo "$SHA512  jansson-$VER.tar.bz2" | sha512sum -c -
		tar -xf "jansson-$VER.tar.bz2"
	]],
		opts
	)
end

function build()
	-- Arch keeps the static library (options=(staticlibs)) and builds it with
	-- fat LTO objects so it stays usable without LTO; do the same.
	cmd(
		[[
		cd "jansson-$VER"
		CFLAGS="${CFLAGS:-} -ffat-lto-objects" ./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "jansson-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("jansson-" .. version .. "/LICENSE")
end

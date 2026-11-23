local version = ZOI.VERSION or "4.1.0"
local sha512 = "bb8f3c47955735253c161b412bd916401afa713736ebe38f12419a1cac0af6ea6db3523853dbd3073b90ab1beec8e0465355801b228386f2027b4ba47adf4869"
-- Release signing key (OpenSSL <openssl@openssl.org>; signed by subkey
-- C46ED3F2CBEFDA1FDAADA44264ED7B1DCCE71CB2), matches Arch's validpgpkeys.
local signing_key = "B146647E45A7B33947AB226B2A2C87D161692D40"

metadata({
	name = "openssl",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "The Open Source toolkit for cryptography and Transport Layer Security (TLS/SSL)",
	website = "https://www.openssl.org",
	license = "Apache-2.0",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The OpenSSL Project Authors",
		website = "https://www.openssl.org",
	},
	bins = {
		"c_rehash",
		"openssl",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/ssl/openssl.cnf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:brotli",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:patch",
					"pacman:perl",
					"pacman:tar",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "openssl-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/openssl/openssl/releases/download/openssl-$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "openssl-$VER.tar.gz"
		fetch "openssl-$VER.tar.gz.asc"
		echo "$SHA512  openssl-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "openssl-$VER.tar.gz"
		cd "openssl-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/ca-dir.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "openssl-$VER"

		./Configure \
			--prefix=/usr \
			--openssldir=/etc/ssl \
			--libdir=lib \
			shared enable-ktls enable-zlib enable-zstd \
			enable-ec_nistp_64_gcc_128 linux-x86_64

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "openssl-$VER"

		make DESTDIR="$ROOT" MANDIR=/usr/share/man MANSUFFIX=ssl install_sw install_ssldirs install_man_docs
		chmod 700 "$ROOT/etc/ssl/private"
	]],
		opts
	)

	zlicense("openssl-" .. version .. "/LICENSE.txt")
end

function test()
	cmd([[
		/usr/bin/openssl version || openssl version || true
	]])
end

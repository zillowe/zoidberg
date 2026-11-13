local version = ZOI.VERSION or "4.1.0"
local tag = "openssl-" .. version
local tar_url = string.format("https://github.com/openssl/openssl/releases/download/%s/%s.tar.gz", tag, tag)

metadata({
	name = "openssl",
	repo = "core",
	version = version,
	revision = "3",
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
					"pacman:gcc",
					"pacman:make",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "openssl-%s" ]; then
			curl -sSL "%s" | tar -xz
		fi

		cd "openssl-%s"
		if [ -f "${PKGLUADIR}/ca-dir.patch" ]; then
			patch -Np1 -i "${PKGLUADIR}/ca-dir.patch" || true
		fi
	]],
		version,
		tar_url,
		version
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "openssl-%s"

		./Configure \
			--prefix=/usr \
			--openssldir=/etc/ssl \
			--libdir=lib \
			shared enable-ktls enable-zlib enable-zstd \
			enable-ec_nistp_64_gcc_128 linux-x86_64

		make -j"$(nproc)"
	]],
		version
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		cd "openssl-%s"

		make DESTDIR="$ROOT" MANDIR=/usr/share/man MANSUFFIX=ssl install_sw install_ssldirs install_man_docs
		chmod 700 "$ROOT/etc/ssl/private" 2>/dev/null || true
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/openssl version || openssl version || true
	]])
end

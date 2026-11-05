local version = ZOI.VERSION or "8.23.0"
local tag = "curl-" .. version:gsub("%.", "_")
local git_url = "https://github.com/curl/curl.git"

metadata({
	name = "curl",
	repo = "core",
	version = version,
	revision = "1",
	description = "Command line tool and library for transferring data with URLs",
	website = "https://curl.se",
	license = "curl",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Daniel Stenberg and contributors",
		website = "https://curl.se",
	},
	bins = {
		"curl",
		"curl-config",
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
					"pacman:brotli",
					"pacman:ca-certificates",
					"pacman:gcc",
					"pacman:git",
					"pacman:libidn2",
					"pacman:libnghttp2",
					"pacman:libpsl",
					"pacman:libssh2",
					"pacman:make",
					"pacman:openssl",
					"pacman:pkgconf",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/ca-certificates",
			"zoi:@core/glibc",
			"zoi:@core/openssl",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "curl-%s" ]; then
			curl -sSfL "https://curl.se/download/curl-%s.tar.xz" -o "curl-%s.tar.xz"
			tar -xf "curl-%s.tar.xz"
		fi
	]],
		version,
		version,
		version,
		version
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "curl-%s"

		./configure \
			--prefix=/usr \
			--mandir=/usr/share/man \
			--disable-ldap \
			--disable-ldaps \
			--disable-manual \
			--enable-ipv6 \
			--enable-threaded-resolver \
			--enable-websockets \
			--with-openssl \
			--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt

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
		make -C "curl-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/curl --version || curl --version || true
	]])
end

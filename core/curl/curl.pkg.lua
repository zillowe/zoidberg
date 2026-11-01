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
	platforms = { "linux" },
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
		if [ ! -d curl ]; then
			git clone --depth 1 --branch "%s" "%s" curl
		fi

		cd curl
		autoreconf -fi 2>/dev/null || ./buildconf 2>/dev/null || true
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd curl

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
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		make -C curl DESTDIR="$ROOT" install
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/curl --version || curl --version || true
	]])
end

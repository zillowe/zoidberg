local version = ZOI.VERSION or "1.71.0"
local sha512 = "3e8702d86ce7fd85e578bf04fcf1283a090d369e9d6530144212726c07c70a5efc53afde16bac877ffc7e8ea7eabc65868e9156e67ce7c424ab5849f4f79cac0"
-- Upstream signs releases (key F4F3B91474D1EB29889BD0EF7E8403D5D673C366, Tatsuhiro Tsujikawa),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "libnghttp2",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Framing layer of the HTTP/2 protocol, implemented as a C library",
	website = "https://nghttp2.org",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Tatsuhiro Tsujikawa",
		website = "https://nghttp2.org",
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
	local tarball = "nghttp2-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/nghttp2/nghttp2/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "nghttp2-$VER.tar.xz"
		echo "$SHA512  nghttp2-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "nghttp2-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "nghttp2-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--disable-examples \
			--disable-python-bindings \
			--enable-lib-only
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "nghttp2-$VER"
		make -C lib DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "nghttp2-" .. version
	zlicense(src .. "/COPYING")
end

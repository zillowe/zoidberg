local version = ZOI.VERSION or "1.3.8"
local sha512 = "390c06b8beeb2b0110ab68953d23fef10c823f598146c7fcebce0cb461d6112d0163eded09fd0b5d3e82d0e189a48184ab3d09b994a41f5cbe4799c16eb1a117"
-- Upstream publishes release tarballs without signatures; the hash below
-- matches the one Arch Linux pins for the same tarball.

metadata({
	name = "libtirpc",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Transport-independent RPC library",
	website = "https://sourceforge.net/projects/libtirpc/",
	license = "BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "libtirpc contributors",
		website = "https://sourceforge.net/projects/libtirpc/",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/netconfig",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:krb5",
					"pacman:make",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/krb5",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libtirpc-" .. version .. ".tar.bz2"
	cmd(
		[[
		fetch() {
			for base in \
				"https://downloads.sourceforge.net/sourceforge/libtirpc"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libtirpc-$VER.tar.bz2"
		echo "$SHA512  libtirpc-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "libtirpc-$VER.tar.bz2"]], opts)
end

function build()
	cmd(
		[[
		cd "libtirpc-$VER"
		# GSSAPI (RPCSEC_GSS) support via krb5, as in Arch
		./configure --prefix=/usr --sysconfdir=/etc --disable-static --enable-gssapi
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libtirpc-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)
	zlicense("libtirpc-" .. version .. "/COPYING")
end

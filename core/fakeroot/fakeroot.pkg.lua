local version = ZOI.VERSION or "2.1.4"
-- Upstream (the Debian maintainer) publishes no tarballs of its own; the
-- release is distributed as Debian's orig tarball, generated from the
-- `upstream/<version>` tag. The hash matches the signed Debian .dsc, and the
-- contents match the salsa.debian.org tag archive.
local sha512 = "533becbe83709c98d55c1fad9995a3dc970c9c47de87c352f67dfd2bf1e3635568a2a08492cade00ec1567083e9c5360c75b8476a3b1049203ae98296b5f6775"

metadata({
	name = "fakeroot",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Tool for simulating superuser privileges",
	website = "https://tracker.debian.org/pkg/fakeroot",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The fakeroot developers",
		website = "https://tracker.debian.org/pkg/fakeroot",
	},
	bins = { "fakeroot", "faked" },
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libtool",
					"pacman:make",
					"pacman:po4a",
					"pacman:systemd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/filesystem",
			"zoi:@core/glibc",
			"zoi:@core/sed",
			"zoi:@core/util-linux",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	-- The release tarball ships no generated build files (upstream no longer
	-- includes them), so configure has to be generated.
	cmd(
		[[
		fetch() {
			for base in \
				"https://deb.debian.org/debian/pool/main/f/fakeroot" \
				"https://ftp.debian.org/debian/pool/main/f/fakeroot"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "fakeroot_$VER.orig.tar.xz"
		echo "$SHA512  fakeroot_$VER.orig.tar.xz" | sha512sum -c -
		tar -xf "fakeroot_$VER.orig.tar.xz"
		cd "fakeroot-$VER"
		autoreconf -fi
	]],
		opts
	)
end

function build()
	-- Perl distributions install po4a into the vendor_perl script dir.
	-- configure looks for po4a, and make then builds the translated man pages.
	cmd(
		[[
		export PATH="$PATH:/usr/bin/vendor_perl"
		cd "fakeroot-$VER"
		./configure \
			--prefix=/usr \
			--libdir=/usr/lib/libfakeroot \
			--disable-static \
			--with-ipc=sysv
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		export PATH="$PATH:/usr/bin/vendor_perl"
		make -C "fakeroot-$VER" DESTDIR="$ROOT" install

		install -dm755 "$ROOT/usr/lib/ld.so.conf.d/"
		echo '/usr/lib/libfakeroot' > "$ROOT/usr/lib/ld.so.conf.d/fakeroot.conf"
	]],
		opts
	)

	zlicense("fakeroot-" .. version .. "/COPYING")
	-- README for sysv/tcp usage
	zdoc("fakeroot-" .. version .. "/README")
end

function test()
	cmd([[
		/usr/bin/fakeroot --version || fakeroot --version
	]])
end

local version = ZOI.VERSION or "1.6.3"
local sha512 = "f65965b8566037078b8eeffa66c6fdbe121c8c2bea7fa5bce04cf7ba5ccc50d5b48e51f4a67ca91e4d5d9a12469e7e3eb3036c920ab25e3feba6e93b4c149cf9"
-- Upstream publishes no release tarball (only signed git tags), so this is
-- git.kernel.org's snapshot of the v<version> tag. The hash matches the one
-- Gentoo records for the same archive (sys-apps/keyutils Manifest).

metadata({
	name = "keyutils",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Linux Key Management Utilities",
	website = "https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git",
	license = "GPL-2.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "David Howells",
		website = "https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git",
	},
	bins = { "keyctl", "request-key", "key.dns_resolver" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/request-key.conf",
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
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
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
			"https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git/snapshot/keyutils-$VER.tar.gz" \
			-o "keyutils-$VER.tar.gz"
		echo "$SHA512  keyutils-$VER.tar.gz" | sha512sum -c -
		tar -xf "keyutils-$VER.tar.gz"
		cd "keyutils-$VER"
		# From Arch Linux: fix the paths of binaries in /etc/request-key.conf
		patch -Np0 -i "$PKGLUADIR/patches/request-key.conf.patch"
		# From Arch Linux: make the build reproducible
		patch -Np1 -i "$PKGLUADIR/patches/reproducible.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "keyutils-$VER"
		make CFLAGS="${CFLAGS:--O2 -pipe}" LDFLAGS="${LDFLAGS:-}" SBINDIR=/usr/bin BINDIR=/usr/bin
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "keyutils-$VER"
		make DESTDIR="$ROOT" SBINDIR=/usr/bin BINDIR=/usr/bin LIBDIR=/usr/lib USRLIBDIR=/usr/lib install
	]],
		opts
	)
	zlicense("keyutils-" .. version .. "/LICENCE.GPL")
	zlicense("keyutils-" .. version .. "/LICENCE.LGPL")
end

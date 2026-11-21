local version = ZOI.VERSION or "2.03.44"
local sha512 = "6dea4cb0d21fff65a8c84ac6cf00a1080547a19c88bab8b2203888c7fb9428447373e33f78566a7abdaf93778ee1d2459c74b545537f9c4a818bc128e4297013"
-- Upstream signs releases (key D501A478440AE2FD130A1BE8B9112431E509039F, Marian Csontos),
-- but every published copy of that key has expired, which Zoi's verifier
-- rejects. The signature was checked with gpg when this hash was recorded;
-- the pinned hash is the trust anchor.

metadata({
	name = "device-mapper",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Device mapper userspace library and tools",
	website = "https://sourceware.org/dm/",
	license = "GPL-2.0-only AND LGPL-2.1-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Red Hat",
		website = "https://sourceware.org/lvm2/",
	},
	bins = { "dmsetup", "dmstats" },
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
					"pacman:pkgconf",
					"pacman:systemd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/systemd:libs",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	local tarball = "LVM2." .. version .. ".tgz"
	sh([[
		fetch() {
			for base in \
				"https://sourceware.org/pub/lvm2" \
				"https://mirrors.kernel.org/sourceware/lvm2"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "LVM2.$VER.tgz"
		echo "$SHA512  LVM2.$VER.tgz" | sha512sum -c -
	]])
	sh([[tar -xf "LVM2.$VER.tgz"]])
end

function build()
	sh([[
		cd "LVM2.$VER"
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--enable-pkgconfig \
			--enable-udev_rules \
			--enable-udev_sync \
			--disable-readline \
			--disable-selinux \
			--disable-sd-notify \
			--disable-systemd-journal \
			--disable-blkid_wiping \
			--without-libaio \
			--with-default-dm-run-dir=/run \
			--with-default-run-dir=/run/lvm \
			--with-udev-prefix=/usr
		make -j"$(nproc)" device-mapper
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "LVM2.$VER"
		make DESTDIR="$ROOT" install_device-mapper
		for f in COPYING COPYING.LIB; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/device-mapper/$(basename "$f")"
		done
		true
	]])
end

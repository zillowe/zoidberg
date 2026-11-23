local version = ZOI.VERSION or "1.11.0"
local sha512 = "a786a1a498aaff30c972d92e5250be269aef06fcd0879b7b9b656fae7f15fa37dd4bb314fc6aa475993065f9b02599b76e0a5cafd5edec8fd9833887d71c26c3"
-- Release signing key (The Tcpdump Group), matches Arch's validpgpkeys.
local signing_key = "1F166A5742ABB9E0249A8D30E089DEF1D9C15D0D"

metadata({
	name = "libpcap",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A system-independent interface for user-level packet capture",
	website = "https://www.tcpdump.org",
	license = "BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Tcpdump Group",
		website = "https://www.tcpdump.org",
	},
	bins = {
		"pcap-config",
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
					"pacman:bison",
					"pacman:curl",
					"pacman:dbus",
					"pacman:flex",
					"pacman:gcc",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			-- pcap-config is a shell script
			"zoi:@core/bash",
			"zoi:@core/dbus",
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libpcap-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.tcpdump.org/release"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libpcap-$VER.tar.xz"
		fetch "libpcap-$VER.tar.xz.sig"
		echo "$SHA512  libpcap-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libpcap-$VER.tar.xz"]], opts)
end

function build()
	-- As Arch (USB and D-Bus capture; IPv6 is always on in 1.11, so Arch's
	-- --enable-ipv6 is no longer a configure option), except: Bluetooth
	-- capture needs bluez-libs and nl80211 monitor-mode support needs libnl,
	-- neither of which Zoidberg ships, so both are disabled explicitly. RDMA
	-- capture is disabled so the build host's rdma-core is never picked up
	-- (Arch does not ship it either).
	cmd(
		[[
		cd "libpcap-$VER"
		./configure \
			--prefix=/usr \
			--enable-usb \
			--enable-dbus \
			--disable-bluetooth \
			--disable-rdma \
			--without-libnl
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "libpcap-$VER" DESTDIR="$ROOT" install
		# Arch ships no static library (makepkg's !staticlibs); match it.
		rm "$ROOT/usr/lib/libpcap.a"
	]],
		opts
	)
	local src = "libpcap-" .. version
	zlicense(src .. "/LICENSE")
	zdoc(src .. "/CHANGES")
	zdoc(src .. "/CONTRIBUTING.md")
	zdoc(src .. "/README.md")
end

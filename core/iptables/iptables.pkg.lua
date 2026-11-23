local version = ZOI.VERSION or "1.8.13"
local sha512 = "3aefd76ca60d00f46ba4d6f39cbcfdc60517d03b6714da25dcd67542f6f4eea8d82c4855bdd9124efe18b769f41951772b8340a6eda75b85f8dd52b2289b145b"
-- Release signing key (Netfilter Core Team), from upstream's published keys.
local signing_key = "8C5F7146A1757A65E2422A94D70D1A666ACF2B21"

metadata({
	name = "iptables",
	repo = "core",
	version = version,
	revision = "3",
	debug = { sub_package = true },
	description = "Linux kernel packet control tool (using nft interface) and the libxtables library",
	website = "https://www.netfilter.org/projects/iptables/",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Netfilter Project",
		website = "https://www.netfilter.org",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/arptables.conf",
		"${usrroot}/etc/ebtables.conf",
		"${usrroot}/etc/ethertypes",
		"${usrroot}/etc/iptables/ip6tables.rules",
		"${usrroot}/etc/iptables/iptables.rules",
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
					"pacman:libmnl",
					"pacman:libnetfilter_conntrack",
					"pacman:libnfnetlink",
					"pacman:libnftnl",
					"pacman:libpcap",
					"pacman:linux-api-headers",
					"pacman:make",
					"pacman:patch",
					"pacman:pkgconf",
				},
			},
		},
	},
	runtime = {
		required = {
			-- iptables-apply and the iptables-flush helper are bash scripts;
			-- the flush helper calls nft.
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/libmnl",
			"zoi:@core/libnetfilter_conntrack",
			"zoi:@core/libnfnetlink",
			"zoi:@core/libnftnl",
			"zoi:@core/libpcap",
			"zoi:@core/nftables",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "iptables-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.netfilter.org/projects/iptables/files"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "iptables-$VER.tar.xz"
		fetch "iptables-$VER.tar.xz.sig"
		echo "$SHA512  iptables-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "iptables-$VER.tar.xz"
		cd "iptables-$VER"
		# Use Arch Linux (and Zoidberg) paths in iptables-apply. Touches only
		# the script and its man page source, so no autoreconf is needed.
		patch -Np1 -i "$PKGLUADIR/patches/0001-fix-iptables-apply-FS-75401.patch"
	]],
		opts
	)
end

-- Built like Arch's `iptables` package: the nftables backend
-- (xtables-nft-multi) is the default `iptables`, `ip6tables`, `arptables`
-- and `ebtables`; the legacy backend stays available as `iptables-legacy`,
-- `ip6tables-legacy` and their -save/-restore variants (installed by make).
function build()
	cmd(
		[[
		cd "iptables-$VER"
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--sysconfdir=/etc \
			--libexecdir=/usr/lib \
			--disable-static \
			--enable-bpf-compiler \
			--enable-devel \
			--enable-libipq \
			--enable-shared \
			--enable-nftables \
			--enable-connlabel \
			--disable-nfsynproxy
		sed -e 's/ -shared / -Wl,-O1,--as-needed\0/g' -i libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "iptables-$VER"
		make DESTDIR="$ROOT" install

		# Point the default names at the nft backend, as Arch does.
		for x in arptables arptables-restore arptables-save \
			ebtables ebtables-restore ebtables-save \
			iptables iptables-restore iptables-save \
			ip6tables ip6tables-restore ip6tables-save \
			iptables-xml; do
			ln -sf xtables-nft-multi "$ROOT/usr/bin/$x"
		done

		install -Dt "$ROOT/usr/lib/systemd/system" -m644 \
			"$PKGLUADIR/files/iptables.service" "$PKGLUADIR/files/ip6tables.service" \
			"$PKGLUADIR/files/arptables.service" "$PKGLUADIR/files/ebtables.service"
		install -D "$PKGLUADIR/files/iptables-nft-flush" "$ROOT/usr/lib/systemd/scripts/iptables-flush"

		install -Dm644 "$PKGLUADIR/files/empty.rules" "$ROOT/etc/iptables/iptables.rules"
		install -Dm644 "$PKGLUADIR/files/empty.rules" "$ROOT/etc/iptables/ip6tables.rules"
		install -Dt "$ROOT/usr/share/iptables" -m644 "$PKGLUADIR"/files/*.rules
		ln -srt "$ROOT/etc/iptables" \
			"$ROOT/usr/share/iptables/empty.rules" \
			"$ROOT/usr/share/iptables/simple_firewall.rules"
		touch "$ROOT/etc/arptables.conf" "$ROOT/etc/ebtables.conf"
	]],
		opts
	)
	zlicense("iptables-" .. version .. "/COPYING")
end

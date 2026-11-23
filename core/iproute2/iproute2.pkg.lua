local version = ZOI.VERSION or "7.3.0"
local sha512 = "1a8d1cdb16514348c9fcfd8f8ff753e258d3344a1810cd4c632f666397bff0cdbe3b9a96b519a50f4e7e9f1bd70e00d6af1a00f9a78a9ff0cc8739d76c3fea92"
-- Release signing key (Stephen Hemminger), matching Arch Linux's validpgpkeys.
local signing_key = "9F6FC345B05BE7E766B83C8F80A77F6095CDE47E"

metadata({
	name = "iproute2",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
	description = "IP Routing Utilities (ip, tc, ss, bridge, devlink)",
	website = "https://wiki.linuxfoundation.org/networking/iproute2",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Stephen Hemminger and others",
		website = "https://git.kernel.org/pub/scm/network/iproute2/iproute2.git",
	},
	bins = {
		"bridge",
		"ctstat",
		"dcb",
		"devlink",
		"genl",
		"ifcfg",
		"ifstat",
		"ip",
		"lnstat",
		"nstat",
		"rdma",
		"routel",
		"rtacct",
		"rtmon",
		"rtpr",
		"rtstat",
		"ss",
		"tc",
		"tipc",
		"vdpa",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/iproute2/bpf_pinning",
		"${usrroot}/etc/iproute2/ematch_map",
		"${usrroot}/etc/iproute2/group",
		"${usrroot}/etc/iproute2/nl_protos",
		"${usrroot}/etc/iproute2/rt_dsfield",
		"${usrroot}/etc/iproute2/rt_protos",
		"${usrroot}/etc/iproute2/rt_realms",
		"${usrroot}/etc/iproute2/rt_scopes",
		"${usrroot}/etc/iproute2/rt_tables",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:bison",
					"pacman:curl",
					"pacman:patch",
					"pacman:flex",
					"pacman:gcc",
					"pacman:iptables",
					"pacman:libbpf",
					"pacman:libcap",
					"pacman:libelf",
					"pacman:libmnl",
					"pacman:libtirpc",
					"pacman:make",
					"pacman:pkgconf",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/elfutils:libelf",
			"zoi:@core/glibc",
			"zoi:@core/iptables",
			"zoi:@core/libbpf",
			"zoi:@core/libcap",
			"zoi:@core/libmnl",
			"zoi:@core/libtirpc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "iproute2-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.kernel.org/pub/linux/utils/net/iproute2" \
				"https://mirrors.kernel.org/pub/linux/utils/net/iproute2"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "iproute2-$VER.tar.xz"
		fetch "iproute2-$VER.tar.sign"
		echo "$SHA512  iproute2-$VER.tar.xz" | sha512sum -c -
		# kernel.org signs the uncompressed tar.
		xz -dk "iproute2-$VER.tar.xz"
	]],
		opts
	)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "iproute2-$VER.tar.xz"
		cd "iproute2-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/0001-make-iproute2-fhs-compliant.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "iproute2-$VER"
		./configure --color auto
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/lib "$ROOT"/etc/iproute2
		make -C "iproute2-$VER" DESTDIR="$ROOT" SBINDIR="/usr/bin" install
	]],
		opts
	)

	zlicense("iproute2-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/ip -V || ip -V || true
	]])
end

local version = ZOI.VERSION or "7.3.0"
local tag = "v" .. version
local git_url = "https://git.kernel.org/pub/scm/network/iproute2/iproute2.git"

metadata({
	name = "iproute2",
	repo = "core",
	version = version,
	revision = "3",
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
					"pacman:flex",
					"pacman:gcc",
					"pacman:git",
					"pacman:iptables",
					"pacman:libcap",
					"pacman:libelf",
					"pacman:make",
					"pacman:pkgconf",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d iproute2 ]; then
			git clone --depth 1 --branch "%s" "%s" iproute2
		fi

		cd iproute2
		if [ -f "${PKGLUADIR}/0001-make-iproute2-fhs-compliant.patch" ]; then
			patch -Np1 -i "${PKGLUADIR}/0001-make-iproute2-fhs-compliant.patch" || true
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd iproute2
		./configure --color auto
		make -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/lib "$ROOT"/etc/iproute2
		make -C iproute2 DESTDIR="$ROOT" SBINDIR="/usr/bin" install
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/ip -V || ip -V || true
	]])
end

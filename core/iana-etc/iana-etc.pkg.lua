local version = ZOI.VERSION or "2026.10.30"
local ports_xml = "service-names-port-numbers-2026.10.28.xml"
local protocols_xml = "protocol-numbers-2026.10.13.xml"

metadata({
	name = "iana-etc",
	repo = "core",
	version = version,
	revision = "2",
	description = "/etc/protocols and /etc/services provided by IANA",
	website = "https://www.iana.org/protocols",
	git = "https://gitlab.com/zillowe/zillowex/parlex/linux/iana-etc.git",
	license = "None",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/protocols",
		"${usrroot}/etc/services",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = { "pacman:gawk" },
			},
		},
	},
})

function prepare()
	local base_url = "https://gitlab.com/zillowe/zillowex/parlex/linux/iana-etc/-/releases/" .. version .. "/downloads/"

	UTILS.DOWNLOAD(
		base_url .. ports_xml,
		ports_xml,
		"9153024bf21f93f8cdbc84f0dbe45d2671f21997a9ed82876da8ecb26ac8374ab1c317af9eca89f8b09a6a57a892a4954bd48a62e2e0b232161a6e3b7780fa55"
	)

	UTILS.DOWNLOAD(
		base_url .. protocols_xml,
		protocols_xml,
		"e8fcdbe8eda9ea338d5ca558f97d6b739e18b9e47e38805126adbbfab7609e02bc5f5371f3888fbd425a3d189cc34f139be80ab85934ed6d70c10a98a8fbde3e"
	)
end

function package()
	zcp(ports_xml, "${usrroot}/usr/share/iana-etc/port-numbers.iana")
	zcp(protocols_xml, "${usrroot}/usr/share/iana-etc/protocol-numbers.iana")

	cmd([[gawk -F"[<>]" '
BEGIN { print "# Full data: /usr/share/iana-etc/protocol-numbers.iana\n" }
(/<record/) { v=n="" }
(/<value/) { v=$3 }
(/<name/ && $3!~/ /) { n=$3 }
(/<\/record/ && n && v!="") { printf "%-12s %3i %s\n", tolower(n),v,n }
' ]] .. protocols_xml .. [[ > protocols]])

	zcp("protocols", "${usrroot}/etc/protocols")

	cmd([[gawk -F"[<>]" '
BEGIN { print "# Full data: /usr/share/iana-etc/port-numbers.iana\n" }
(/<record/) { n=u=p=c="" }
(/<name/ && !/\(/) { n=$3 }
(/<number/) { u=$3 }
(/<protocol/) { p=$3 }
(/Unassigned/ || /Reserved/ || /historic/) { c=1 }
(/<\/record/ && n && u && p && !c) { printf "%-15s %5i/%s\n", n,u,p }
' ]] .. ports_xml .. [[ > services]])

	zcp("services", "${usrroot}/etc/services")

	zlicense("${pkgluadir}/license-from-upstream")
end

function test()
	cmd([[
		test -f /etc/protocols && test -f /etc/services || true
	]])
end

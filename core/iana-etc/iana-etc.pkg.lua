local version = ZOI.VERSION or "2026.10.30"
local ports_xml = "service-names-port-numbers-2026.10.28.xml"
local protocols_xml = "protocol-numbers-2026.10.13.xml"

metadata({
	name = "iana-etc",
	repo = "core",
	version = version,
	revision = "1",
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
	platforms = { "linux" },
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
		"00a3e9b9d7aa7fe392891f1af7377ad525e8975e6e1fc57b654303669c974ce204de1a690071b2346a11f8ebebdeef752ba850a9e80c04b5393016ec6849e740"
	)

	UTILS.DOWNLOAD(
		base_url .. protocols_xml,
		protocols_xml,
		"54c52c71aceed248e0e1b3a4da4853e32654a4f91f2f2fac938b91a282a2bdb9ffac82d15e88349e26c3ebf175e04b80af8ba3fcc1e20d65fbb2186811244c6a"
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

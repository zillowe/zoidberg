local version = ZOI.VERSION or "2026.08.06"
local ports_xml = "service-names-port-numbers-2026.08.05.xml"
local protocols_xml = "protocol-numbers-2026.03.10.xml"

metadata({
	name = "iana-etc",
	repo = "core",
	version = version,
	revision = "1",
	description = "/etc/protocols and /etc/services provided by IANA",
	website = "https://www.iana.org/protocols",
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
				required = { "zoi:@core/gawk" },
			},
		},
	},
})

function prepare()
	local base_url = "https://gitlab.com/zillowe/zillowex/parlex/linux/iana-etc/-/releases/" .. version .. "/downloads/"

	UTILS.DOWNLOAD(
		base_url .. ports_xml,
		ports_xml,
		"db00355924e23ce5786fc3b6564132eeaeb13a00f9128bc92249da7b9130b9e93d2e09140ba7980a61e6950b4b725faa9a453ecf79ae4dda820f9fb13fc8790f"
	)

	UTILS.DOWNLOAD(
		base_url .. protocols_xml,
		protocols_xml,
		"66f962a575d1bdffb230081f2b3e409355fdd8a1d6966d1665f51e6ebe718b92c66c6373947625e7de7c6050b640210a472d7150773f320b9289b5cf5b2a7ec2"
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

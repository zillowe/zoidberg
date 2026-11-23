local version = ZOI.VERSION or "2026.11.23"
local ports_xml = "service-names-port-numbers-2026.11.20.xml"
local protocols_xml = "protocol-numbers-2026.10.13.xml"
local ports_sha512 =
	"7a979cd35aadc9f1dabff665ce7684b992633a5171535474b0a2a88136f2d524be32387e4661386a52b650374278043f08aa646e1fc2b12bf72d3a490ceb9edf"
local protocols_sha512 =
	"e8fcdbe8eda9ea338d5ca558f97d6b739e18b9e47e38805126adbbfab7609e02bc5f5371f3888fbd425a3d189cc34f139be80ab85934ed6d70c10a98a8fbde3e"

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

local opts = {
	check = true,
	env = {
		VER = version,
		PORTS = ports_xml,
		PORTS_SHA512 = ports_sha512,
		PROTOCOLS = protocols_xml,
		PROTOCOLS_SHA512 = protocols_sha512,
	},
}

function prepare()
	cmd(
		[[
		base="https://gitlab.com/zillowe/zillowex/parlex/linux/iana-etc/-/releases/$VER/downloads"
		curl -sSfL --retry 3 --retry-all-errors "$base/$PORTS" -o "$PORTS"
		curl -sSfL --retry 3 --retry-all-errors "$base/$PROTOCOLS" -o "$PROTOCOLS"
		echo "$PORTS_SHA512  $PORTS" | sha512sum -c -
		echo "$PROTOCOLS_SHA512  $PROTOCOLS" | sha512sum -c -
	]],
		opts
	)
end

function build()
	cmd(
		[[
		gawk -F"[<>]" '
			BEGIN { print "# Full data: /usr/share/iana-etc/protocol-numbers.iana\n" }
			(/<record/) { v=n="" }
			(/<value/) { v=$3 }
			(/<name/ && $3!~/ /) { n=$3 }
			(/<\/record/ && n && v!="") { printf "%-12s %3i %s\n", tolower(n),v,n }
		' "$PROTOCOLS" > protocols
		gawk -F"[<>]" '
			BEGIN { print "# Full data: /usr/share/iana-etc/port-numbers.iana\n" }
			(/<record/) { n=u=p=c="" }
			(/<name/ && !/\(/) { n=$3 }
			(/<number/) { u=$3 }
			(/<protocol/) { p=$3 }
			(/Unassigned/ || /Reserved/ || /historic/) { c=1 }
			(/<\/record/ && n && u && p && !c) { printf "%-15s %5i/%s\n", n,u,p }
		' "$PORTS" > services
		test -s protocols
		test -s services
	]],
		opts
	)
end

function package()
	zcp(ports_xml, "${usrroot}/usr/share/iana-etc/port-numbers.iana")
	zcp(protocols_xml, "${usrroot}/usr/share/iana-etc/protocol-numbers.iana")
	zcp("protocols", "${usrroot}/etc/protocols")
	zcp("services", "${usrroot}/etc/services")

	zlicense("${pkgluadir}/files/license-from-upstream")
end

function test()
	cmd(
		[[
		grep -Eq '^tcp +6 TCP$' protocols
		grep -Eq '^ssh +22/tcp$' services
	]],
		opts
	)
	return true
end

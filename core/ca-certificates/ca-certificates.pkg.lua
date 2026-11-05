local version = ZOI.VERSION or "20240618"

metadata({
	name = "ca-certificates",
	repo = "core",
	version = version,
	revision = "1",
	description = "Common CA certificates and trust management utilities",
	website = "https://src.fedoraproject.org/rpms/ca-certificates",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Fedora ca-certificates contributors",
		website = "https://src.fedoraproject.org/rpms/ca-certificates",
	},
	bins = {
		"update-ca-trust",
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
					"pacman:asciidoc",
					"pacman:coreutils",
					"pacman:p11-kit",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/coreutils",
			"zoi:@core/findutils",
		},
	},
})

hooks({
	post_install = {
		[[
		if [ -x /usr/bin/update-ca-trust ]; then
			/usr/bin/update-ca-trust 2>/dev/null || true
		fi
		]],
	},
})

function prepare()
	-- Source files are packaged directly in the repository
end

function build()
	cmd([[
		if [ -f update-ca-trust.8.txt ]; then
			a2x -v -f manpage update-ca-trust.8.txt 2>/dev/null || true
		fi
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")
	local pkgdir = LOCATION.PKGLUADIR or "."

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		PKGLUADIR="%s"
		mkdir -p "$ROOT"/usr/bin "$ROOT"/usr/share/man/man8

		install -m755 "${PKGLUADIR}/update-ca-trust" "$ROOT"/usr/bin/update-ca-trust
		if [ -f update-ca-trust.8 ]; then
			install -m644 update-ca-trust.8 "$ROOT"/usr/share/man/man8/
		fi

		etcdir="$ROOT/etc/ca-certificates"
		ssldir="$ROOT/etc/ssl"
		usrdir="$ROOT/usr/share/ca-certificates"

		mkdir -p "$etcdir"/trust-source/{anchors,blocklist} \
			"$usrdir"/trust-source/{anchors,blocklist} \
			"$etcdir"/extracted \
			"$ssldir"/certs/java

		if [ -f "${PKGLUADIR}/README.etc" ]; then
			install -m644 "${PKGLUADIR}/README.etc" "$etcdir/README"
		fi
		if [ -f "${PKGLUADIR}/README.src" ]; then
			install -m644 "${PKGLUADIR}/README.src" "$etcdir/trust-source/README"
		fi
		if [ -f "${PKGLUADIR}/README.usr" ]; then
			install -m644 "${PKGLUADIR}/README.usr" "$usrdir/trust-source/README"
		fi
		if [ -f "${PKGLUADIR}/README.etcssl" ]; then
			install -m644 "${PKGLUADIR}/README.etcssl" "$ssldir/README"
		fi
		if [ -f "${PKGLUADIR}/README.extr" ]; then
			install -m644 "${PKGLUADIR}/README.extr" "$etcdir/extracted/README"
		fi

		# OpenSSL / Debian / Fedora compatibility symlinks
		ln -sf /etc/ca-certificates/extracted/tls-ca-bundle.pem "$ssldir/cert.pem"
		ln -sf /etc/ca-certificates/extracted/tls-ca-bundle.pem "$ssldir/certs/ca-certificates.crt"
		ln -sf /etc/ca-certificates/extracted/tls-ca-bundle.pem "$ssldir/certs/ca-bundle.crt"
	]],
		root,
		pkgdir
	))

	zcp("${pkgluadir}/hooks/update-ca-trust.hook.yaml", "${pkgstore}/hooks/update-ca-trust.hook.yaml")

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/update-ca-trust --help || update-ca-trust --help || true
	]])
end

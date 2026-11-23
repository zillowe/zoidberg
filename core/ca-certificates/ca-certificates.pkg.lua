local version = ZOI.VERSION or "20240618"

metadata({
	name = "ca-certificates",
	repo = "core",
	version = version,
	revision = "6",
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
			"zoi:@core/ca-certificates-mozilla",
			"zoi:@core/coreutils",
			"zoi:@core/findutils",
			"zoi:@core/p11-kit",
		},
	},
})

hooks({
	post_install = {
		[[
		/usr/bin/update-ca-trust
		]],
	},
})

local opts = { check = true }

function prepare()
	-- Source files are packaged directly in the repository
end

function build()
	cmd([[a2x -v -f manpage -D . "$PKGLUADIR/files/update-ca-trust.8.txt"]], opts)
end

function package()
	cmd(
		[[
		install -Dm755 "$PKGLUADIR/files/update-ca-trust" "$ROOT/usr/bin/update-ca-trust"
		install -Dm644 update-ca-trust.8 "$ROOT/usr/share/man/man8/update-ca-trust.8"

		etcdir="$ROOT/etc/ca-certificates"
		ssldir="$ROOT/etc/ssl"
		usrdir="$ROOT/usr/share/ca-certificates"

		mkdir -p "$etcdir"/trust-source/{anchors,blocklist} \
			"$usrdir"/trust-source/{anchors,blocklist} \
			"$etcdir"/extracted \
			"$ssldir"/certs/java

		install -m644 "$PKGLUADIR/files/README.etc" "$etcdir/README"
		install -m644 "$PKGLUADIR/files/README.src" "$etcdir/trust-source/README"
		install -m644 "$PKGLUADIR/files/README.usr" "$usrdir/trust-source/README"
		install -m644 "$PKGLUADIR/files/README.etcssl" "$ssldir/README"
		install -m644 "$PKGLUADIR/files/README.java" "$ssldir/certs/java/README"
		install -m644 "$PKGLUADIR/files/README.extr" "$etcdir/extracted/README"

		# OpenSSL / Debian / Fedora compatibility symlinks
		ln -sf /etc/ca-certificates/extracted/tls-ca-bundle.pem "$ssldir/cert.pem"
		ln -sf /etc/ca-certificates/extracted/tls-ca-bundle.pem "$ssldir/certs/ca-certificates.crt"
		ln -sf /etc/ca-certificates/extracted/tls-ca-bundle.pem "$ssldir/certs/ca-bundle.crt"
	]],
		opts
	)

	zcp("${pkgluadir}/hooks/update-ca-trust.hook.yaml", "${pkgstore}/hooks/update-ca-trust.hook.yaml")

	-- update-ca-trust and the READMEs come from the Fedora / Arch Linux
	-- ca-certificates packaging (GPL-2.0-or-later), which ships no license
	-- file: install a
	-- copy of the GPL-2.0 text (from gnu.org) kept next to this recipe.
	zlicense("${pkgluadir}/files/LICENSE.GPL-2.0", "LICENSE")
end

function test()
	cmd(
		[[
		test -x "$ROOT/usr/bin/update-ca-trust"
		bash -n "$ROOT/usr/bin/update-ca-trust"
		test -f "$ROOT/usr/share/man/man8/update-ca-trust.8"
	]],
		opts
	)
	return true
end

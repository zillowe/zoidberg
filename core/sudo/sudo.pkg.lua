local version = ZOI.VERSION or "1.9.17.p2"
-- Upstream writes the version as 1.9.17p2.
local raw_version = string.gsub(version, "%.p", "p")
local sha512 = "c8abd6ca56e54a081c9ef1e9f6579d1db5b93ff857e60d1f58d1f425d7dc23c31c58d40b7819780688f66dfdf87a1f3bbe0a78387b007e2beb1b0e546203ea93"
-- Release signing key (Todd C. Miller), matches Arch's validpgpkeys.
local signing_key = "59D1E9CCBA2B376704FDD35BA9F4C021CEA470FB"

metadata({
	name = "sudo",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "Give certain users the ability to run some commands as root",
	website = "https://www.sudo.ws/sudo/",
	license = "ISC",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Todd C. Miller",
		website = "https://www.sudo.ws/sudo/",
	},
	bins = {
		"cvtsudoers",
		"sudo",
		"sudoedit",
		"sudoreplay",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/pam.d/sudo",
		"${usrroot}/etc/sudo.conf",
		"${usrroot}/etc/sudo_logsrvd.conf",
		"${usrroot}/etc/sudoers",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:libldap",
					"pacman:make",
					"pacman:openssl",
					"pacman:pam",
					"pacman:patch",
					"pacman:tar",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/openldap:libs",
			"zoi:@core/openssl",
			"zoi:@core/pam",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = raw_version, SHA512 = sha512 } }

function prepare()
	local tarball = "sudo-" .. raw_version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.sudo.ws/dist" \
				"https://www.sudo.ws/sudo/dist"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "sudo-$VER.tar.gz"
		fetch "sudo-$VER.tar.gz.sig"
		echo "$SHA512  sudo-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "sudo-$VER.tar.gz"
		cd "sudo-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/openssl-4.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "sudo-$VER"

		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--libexecdir=/usr/lib \
			--with-rundir=/run/sudo \
			--with-vardir=/var/db/sudo \
			--with-logfac=auth \
			--enable-tmpfiles.d \
			--with-pam \
			--with-sssd \
			--with-ldap \
			--with-ldap-conf-file=/etc/openldap/ldap.conf \
			--with-env-editor \
			--with-passprompt="[sudo] password for %p: " \
			--with-secure-path-value=/usr/local/sbin:/usr/local/bin:/usr/bin \
			--with-all-insults

		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/etc/pam.d "$ROOT"/usr/lib/systemd/system

		make -C "sudo-$VER" DESTDIR="$ROOT" install

		install -m644 "$PKGLUADIR/files/sudo_logsrvd.service" "$ROOT/usr/lib/systemd/system/sudo_logsrvd.service"
		install -m644 "$PKGLUADIR/files/sudo.pam" "$ROOT/etc/pam.d/sudo"

		rm -f "$ROOT/etc/sudoers.dist"
		rm -rf "$ROOT/run"
	]],
		opts
	)

	zlicense("sudo-" .. raw_version .. "/LICENSE.md")
end

function test()
	cmd([[
		/usr/bin/sudo --version || sudo --version
	]])
end

local version = ZOI.VERSION or "2.8"
local sha512 = "00b33c9d712cf670f16dbefc963fed880088ff67f506df54fd02fdfc0f8c05d379faba5d602c8772c4dc4fd72e1fa8733777d5840784aa86e092eeb5d0f905f7"
-- Release signing key (Simon Josefsson), one of those Arch Linux lists.
local signing_key = "B1D2BD1375BECB784CF4F8C4D73CF638C53C06BE"

metadata({
	name = "inetutils",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A collection of common network programs",
	website = "https://www.gnu.org/software/inetutils/",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = {
		"dnsdomainname",
		"ftp",
		"hostname",
		"rcp",
		"rlogin",
		"rsh",
		"talk",
		"telnet",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/pam.d/rlogin",
		"${usrroot}/etc/pam.d/rsh",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:gcc",
					"pacman:libcap",
					"pacman:libxcrypt",
					"pacman:make",
					"pacman:ncurses",
					"pacman:pam",
					"pacman:readline",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libcap",
			"zoi:@core/libxcrypt",
			"zoi:@core/ncurses",
			"zoi:@core/pam",
			"zoi:@core/readline",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "inetutils-" .. version .. ".tar.gz"
	-- The release tarball (Arch Linux builds the signed git tag; the
	-- tarball is the same release with its generated files included).
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/inetutils" \
				"https://mirrors.kernel.org/gnu/inetutils" \
				"https://ftp.gnu.org/gnu/inetutils"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "inetutils-$VER.tar.gz"
		fetch "inetutils-$VER.tar.gz.sig"
		echo "$SHA512  inetutils-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "inetutils-$VER.tar.gz"]], opts)
end

function build()
	-- Options follow Arch Linux's PKGBUILD: the clients and daemons Arch
	-- ships, without the programs other packages provide (ping, logger,
	-- syslogd, ifconfig, traceroute, whois, inetd) or that are insecure
	-- (rexec, tftp, uucpd).
	cmd(
		[[
		cd "inetutils-$VER"
		./configure \
			--prefix=/usr \
			--libexec=/usr/bin \
			--localstatedir=/var \
			--sysconfdir=/etc \
			--without-wrap \
			--with-pam \
			--enable-ftp \
			--enable-ftpd \
			--enable-telnet \
			--enable-telnetd \
			--enable-talk \
			--enable-talkd \
			--enable-rlogin \
			--enable-rlogind \
			--enable-rsh \
			--enable-rshd \
			--enable-rcp \
			--enable-hostname \
			--enable-dnsdomainname \
			--disable-rexec \
			--disable-rexecd \
			--disable-tftp \
			--disable-tftpd \
			--disable-ping \
			--disable-ping6 \
			--disable-logger \
			--disable-syslogd \
			--disable-inetd \
			--disable-whois \
			--disable-uucpd \
			--disable-ifconfig \
			--disable-traceroute

		# As Arch Linux: ncurses provides tgetent through term.h.
		sed -i '/HAVE_CURSES_TGETENT/c #define HAVE_CURSES_TGETENT 1' config.h
		sed -i '/# include <curses.h>/a # include <term.h>' telnet/telnet.c telnetd/utility.c

		make
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "inetutils-$VER"
		make DESTDIR="$ROOT" install

		# rcp, rlogin and rsh get cap_net_bind_service in post_install
		# instead of setuid root.
		chmod -s "$ROOT"/usr/bin/rcp "$ROOT"/usr/bin/rlogin "$ROOT"/usr/bin/rsh

		files="$PKGLUADIR/files"
		install -Dm644 "$files/rlogin.pam" "$ROOT/etc/pam.d/rlogin"
		install -Dm644 "$files/rsh.pam" "$ROOT/etc/pam.d/rsh"
		units="$ROOT/usr/lib/systemd/system"
		for unit in ftpd.service rlogin@.service rlogin.socket rsh@.service \
			rsh.socket talk.service talk.socket telnet@.service telnet.socket; do
			install -Dm644 "$files/$unit" "$units/$unit"
		done
		install -Dm644 "$files/inetutils.sysusers" "$ROOT/usr/lib/sysusers.d/inetutils.conf"
	]],
		opts
	)

	zlicense("inetutils-" .. version .. "/COPYING")
end

-- As Arch Linux's inetutils.install: the r-commands bind privileged ports,
-- through a capability where the filesystem supports it, else setuid.
hooks({
	post_install = {
		[[
		for prog in rcp rlogin rsh; do
			setcap cap_net_bind_service=+ep "/usr/bin/$prog" 2>/dev/null ||
				chmod u+s "/usr/bin/$prog"
		done
		]],
	},
	post_upgrade = {
		[[
		for prog in rcp rlogin rsh; do
			setcap cap_net_bind_service=+ep "/usr/bin/$prog" 2>/dev/null ||
				chmod u+s "/usr/bin/$prog"
		done
		]],
	},
})

function test()
	cmd([["$ROOT/usr/bin/hostname" --version]], opts)
	return true
end

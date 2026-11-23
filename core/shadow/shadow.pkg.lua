local version = ZOI.VERSION or "4.20.4"
local sha512 = "1796f860b229b6e2dbfeecc4bb26dcbe2558be71bddb207fe54be3665aea68dff9620bdc1eb9b749072d6f55a2535f33c0efd4fcb3e8ba3bffbecea9a17bbaec"
-- Release signing key (Alejandro Colomar; signed by subkey
-- 4BB26DF6EF466E6956003022EB89995CC290C2A9), matches Arch's validpgpkeys.
local signing_key = "A9348594CE31283A826FBDD8D57633D441E25BB5"

metadata({
	name = "shadow",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Password and account management tool suite with support for shadow files and PAM",
	website = "https://github.com/shadow-maint/shadow",
	license = "0BSD AND BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Shadow Maintainers",
		website = "https://github.com/shadow-maint/shadow",
	},
	bins = {
		"chage",
		"chgpasswd",
		"chpasswd",
		"expiry",
		"faillog",
		"gpasswd",
		"groupadd",
		"groupdel",
		"groupmems",
		"groupmod",
		"grpck",
		"grpconv",
		"grpunconv",
		"lastlog",
		"newgidmap",
		"newuidmap",
		"newusers",
		"passwd",
		"pwck",
		"pwconv",
		"pwunconv",
		"useradd",
		"userdel",
		"usermod",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/default/useradd",
		"${usrroot}/etc/login.defs",
		"${usrroot}/etc/pam.d/chpasswd",
		"${usrroot}/etc/pam.d/newusers",
		"${usrroot}/etc/pam.d/passwd",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:acl",
					"pacman:audit",
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:docbook-xsl",
					"pacman:gcc",
					"pacman:itstool",
					"pacman:libcap",
					"pacman:libtool",
					"pacman:libxcrypt",
					"pacman:libxslt",
					"pacman:make",
					"pacman:pam",
					"pacman:patch",
					"pacman:pkgconf",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/acl",
			"zoi:@core/attr",
			"zoi:@core/audit",
			"zoi:@core/glibc",
			"zoi:@core/libxcrypt",
			"zoi:@core/pam",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "shadow-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/shadow-maint/shadow/releases/download/$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "shadow-$VER.tar.xz"
		fetch "shadow-$VER.tar.xz.asc"
		echo "$SHA512  shadow-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "shadow-$VER.tar.xz"
		cd "shadow-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/shadow.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "shadow-$VER"

		# Keep the shipped generated files (no autoreconf). The Makefile.am
		# hunks of shadow.patch therefore have no effect; package() removes
		# the util-linux tools instead.
		find . -type f \( -name "config.hin" -o -name "configh.in" -o -name "config.h.in" -o -name "Makefile.in" -o -name "aclocal.m4" -o -name "configure" \) -exec touch -c {} +

		export CFLAGS="${CFLAGS} -DEXTRA_CHECK_HOME_DIR"

		./configure \
			--bindir=/usr/bin \
			--sbindir=/usr/bin \
			--libdir=/usr/lib \
			--mandir=/usr/share/man \
			--prefix=/usr \
			--sysconfdir=/etc \
			--enable-man \
			--with-audit \
			--with-fcaps \
			--with-group-name-max-length=32 \
			--with-libpam \
			--with-yescrypt \
			--without-bcrypt \
			--without-libbsd \
			--without-nscd \
			--without-selinux \
			--without-su

		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"/etc/default "$ROOT"/usr/lib/systemd/system

		# With --enable-man the top-level install also installs man/.
		make -C "shadow-$VER" DESTDIR="$ROOT" install

		# util-linux provides these, as on Arch; shipping both is a file
		# conflict between the two packages. shadow keeps vipw and vigr.
		rm -f "$ROOT"/usr/bin/{chfn,chsh,login,newgrp,nologin}
		rm -f "$ROOT"/etc/pam.d/{chfn,chsh,login}
		rm -f "$ROOT"/usr/share/man/man1/{chfn,chsh,login,newgrp}.1
		rm -f "$ROOT"/usr/share/man/man8/nologin.8

		# /usr/sbin is a symlink to bin on Parlex (merged /usr). Files recorded
		# under sbin would hide conflicts with packages using bin.
		if [ -d "$ROOT/usr/sbin" ] && [ ! -L "$ROOT/usr/sbin" ]; then
			mkdir -p "$ROOT/usr/bin"
			mv "$ROOT"/usr/sbin/* "$ROOT"/usr/bin/
			rmdir "$ROOT/usr/sbin"
		fi

		install -m600 "$PKGLUADIR/files/useradd.defaults" "$ROOT/etc/default/useradd"

		install -m644 "$PKGLUADIR/files/shadow.timer" "$ROOT/usr/lib/systemd/system/shadow.timer"
		install -m644 "$PKGLUADIR/files/shadow.service" "$ROOT/usr/lib/systemd/system/shadow.service"
	]],
		opts
	)

	zlicense("shadow-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/passwd --help || /usr/bin/useradd --help || true
	]])
end

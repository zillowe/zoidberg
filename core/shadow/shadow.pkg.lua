local version = ZOI.VERSION or "4.20.0"
local git_url = "https://github.com/shadow-maint/shadow.git"

metadata({
	name = "shadow",
	repo = "core",
	version = version,
	revision = "2",
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
					"pacman:git",
					"pacman:itstool",
					"pacman:libcap",
					"pacman:libtool",
					"pacman:libxcrypt",
					"pacman:libxslt",
					"pacman:make",
					"pacman:pam",
					"pacman:patch",
					"pacman:zstd",
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
		if [ ! -d shadow ]; then
			git clone --depth 1 --branch "%s" "%s" shadow
		fi

		cd shadow
		if [ -f "${PKGLUADIR}/shadow.patch" ]; then
			patch -Np1 -i "${PKGLUADIR}/shadow.patch" || true
		fi
		autoreconf -fiv
	]],
		version,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd shadow

		export CFLAGS="${CFLAGS} -DEXTRA_CHECK_HOME_DIR"

		./configure \
			--bindir=/usr/bin \
			--sbindir=/usr/bin \
			--libdir=/usr/lib \
			--mandir=/usr/share/man \
			--prefix=/usr \
			--sysconfdir=/etc \
			--disable-account-tools-setuid \
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

		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool 2>/dev/null || true
		make -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"/etc/default "$ROOT"/usr/share/licenses/shadow "$ROOT"/usr/lib/systemd/system

		make -C shadow DESTDIR="$ROOT" install
		make -C shadow/man DESTDIR="$ROOT" install 2>/dev/null || true

		install -m644 shadow/COPYING "$ROOT/usr/share/licenses/shadow/COPYING" 2>/dev/null || true
		install -m600 "${PKGLUADIR}/useradd.defaults" "$ROOT/etc/default/useradd"

		install -m644 "${PKGLUADIR}/shadow.timer" "$ROOT/usr/lib/systemd/system/shadow.timer"
		install -m644 "${PKGLUADIR}/shadow.service" "$ROOT/usr/lib/systemd/system/shadow.service"
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/passwd --help || /usr/bin/useradd --help || true
	]])
end

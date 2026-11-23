local version = ZOI.VERSION or "1.16.4"
local sha512 =
	"edcd1102184e4a81da905a7a554531bcba74d4e037240c27b3cf1af8ed308df6ae6182fd8af0c98894c56b6d24100787893d6a86e430f4077c23c8a3a5f530a2"
-- Release signing key (Simon McVittie), matching Arch Linux's validpgpkeys.
-- Releases are signed by its subkey 7A073AD1AE694FA25BFF62E5235C099D3EB33076.
local signing_key = "DA98F25C0871C49A59EAFF2C4DE8FF2A63C7CC90"

metadata({
	name = "dbus",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Freedesktop.org message bus system",
	website = "https://www.freedesktop.org/wiki/Software/dbus/",
	license = "AFL-2.1 OR GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The D-Bus developers",
		website = "https://gitlab.freedesktop.org/dbus/dbus",
	},
	bins = {
		"dbus-cleanup-sockets",
		"dbus-daemon",
		"dbus-launch",
		"dbus-monitor",
		"dbus-run-session",
		"dbus-send",
		"dbus-test-tool",
		"dbus-update-activation-environment",
		"dbus-uuidgen",
	},
	provides = { "libdbus" },
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
					"pacman:audit",
					"pacman:curl",
					"pacman:docbook-xsl",
					"pacman:expat",
					"pacman:gcc",
					"pacman:libcap-ng",
					"pacman:meson",
					"pacman:ninja",
					"pacman:patch",
					"pacman:pkgconf",
					"pacman:python",
					"pacman:systemd",
					"pacman:tar",
					"pacman:xmlto",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/audit",
			"zoi:@core/expat",
			"zoi:@core/glibc",
			"zoi:@core/libcap-ng",
			"zoi:@core/systemd:libs",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "dbus-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://dbus.freedesktop.org/releases/dbus"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "dbus-$VER.tar.xz"
		fetch "dbus-$VER.tar.xz.asc"
		echo "$SHA512  dbus-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	-- 0001: upstream commit 2cb5882d (lock the dbus system account), as Arch.
	-- 0002: Arch's tweaks (no legacy config, no packaged runstatedir, the
	--       message bus user gets the fixed UID 81).
	cmd(
		[[
		tar -xf "dbus-$VER.tar.xz"
		cd "dbus-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/0001-systemd-create-locked-dbus-user-if-possible.patch"
		patch -Np1 -i "$PKGLUADIR/patches/0002-Arch-Linux-tweaks.patch"
	]],
		opts
	)
end

function build()
	-- Options as Arch. The API documentation (doxygen, ducktype, Qt help) is
	-- Arch's separate dbus-docs package and is not built; the man pages are.
	cmd(
		[[
		meson setup "dbus-$VER" build \
			--prefix=/usr \
			--libexecdir=lib \
			--sbindir=bin \
			--buildtype=plain \
			--wrap-mode=nodownload \
			-Db_pie=true \
			-Dapparmor=disabled \
			-Ddbus_user=dbus \
			-Dkqueue=disabled \
			-Dlaunchd=disabled \
			-Drelocation=disabled \
			-Dselinux=disabled \
			-Dx11_autolaunch=disabled \
			-Dlibaudit=enabled \
			-Dsystemd=enabled \
			-Dxml_docs=enabled \
			-Ddoxygen_docs=disabled \
			-Dducktype_docs=disabled \
			-Dqt_help=disabled \
			-Dmodular_tests=disabled \
			-Dinstalled_tests=false
		meson compile -C build -j"$(nproc)"
	]],
		opts
	)
end

function package()
	-- dbus-broker (provides "dbus-units") owns dbus.service, as Arch's
	-- dbus-broker-units; dbus keeps dbus.socket, the daemon, the library and
	-- the tools. The dbus system user comes from usr/lib/sysusers.d/dbus.conf
	-- (created by systemd's sysusers hook).
	cmd(
		[[
		meson install -C build --destdir "$ROOT"
		rm -f "$ROOT"/usr/lib/systemd/system/dbus.service "$ROOT"/usr/lib/systemd/user/dbus.service
		rm -rf "$ROOT"/usr/share/doc/dbus
	]],
		opts
	)
	zcp("${pkgluadir}/hooks/dbus-reload.hook.yaml", "${pkgstore}/hooks/dbus-reload.hook.yaml")
	zlicense("dbus-" .. version .. "/COPYING")
	zlicense("dbus-" .. version .. "/LICENSES/AFL-2.1.txt")
	zlicense("dbus-" .. version .. "/LICENSES/GPL-2.0-or-later.txt")
	zdoc("dbus-" .. version .. "/NEWS")
	zdoc("dbus-" .. version .. "/README")
end

function test()
	cmd([[
		/usr/bin/dbus-daemon --version || dbus-daemon --version
	]])
end

local version = ZOI.VERSION or "37"
local sha512 =
	"9f7c8aa4fabd1fc2da7b521a742874dd0e54f12c24fd5b9a3cbc91e8de05b9d08299cb0b353b923a6b8e33be194222e0242b6ba7cad795a350e7d056b7303e13"
-- Release signing key (David Herrmann), matching Arch Linux's validpgpkeys.
local signing_key = "BE5FBC8C9C1C9F60A4F0AEAE7A4F3A09EBDEFF26"

metadata({
	name = "dbus-broker",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Linux D-Bus Message Broker (with the dbus.service units)",
	website = "https://github.com/bus1/dbus-broker/wiki",
	license = "Apache-2.0",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "David Rheinsberg, Tom Gundersen and others",
		website = "https://github.com/bus1/dbus-broker",
	},
	bins = { "dbus-broker", "dbus-broker-launch" },
	-- Arch's dbus-broker + dbus-broker-units: this package owns
	-- dbus.service (system and user), dbus keeps dbus.socket.
	provides = { "dbus-units" },
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
					"pacman:expat",
					"pacman:gcc",
					"pacman:libcap-ng",
					"pacman:meson",
					"pacman:ninja",
					"pacman:patch",
					"pacman:pkgconf",
					"pacman:python-docutils",
					"pacman:systemd",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/audit",
			"zoi:@core/dbus",
			"zoi:@core/expat",
			"zoi:@core/gcc:libgcc",
			"zoi:@core/glibc",
			"zoi:@core/libcap-ng",
			"zoi:@core/systemd:libs",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "dbus-broker-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/bus1/dbus-broker/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "dbus-broker-$VER.tar.xz"
		fetch "dbus-broker-$VER.tar.xz.asc"
		echo "$SHA512  dbus-broker-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	-- Patches from Arch Linux: 0001 installs dbus.service as a static alias
	-- of dbus-broker.service, 0002 fixes the test suite on newer kernels.
	cmd(
		[[
		tar -xf "dbus-broker-$VER.tar.xz"
		cd "dbus-broker-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/0001-units-Enable-statically.patch"
		patch -Np1 -i "$PKGLUADIR/patches/0002-test-sockopt-loosen-verification-of-stale-pidfds.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		meson setup "dbus-broker-$VER" build \
			--prefix=/usr \
			--libexecdir=lib \
			--sbindir=bin \
			--buildtype=plain \
			--wrap-mode=nodownload \
			-Db_pie=true \
			-Daudit=true \
			-Ddocs=true \
			-Dlinux-4-17=true \
			-Dsystem-console-users=gdm,sddm,lightdm,lxdm
		meson compile -C build -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[meson install -C build --destdir "$ROOT"]], opts)
	zlicense("dbus-broker-" .. version .. "/LICENSE")
	zdoc("dbus-broker-" .. version .. "/NEWS.md")
	zdoc("dbus-broker-" .. version .. "/README.md")
end

function test()
	cmd([[
		/usr/bin/dbus-broker --version || dbus-broker --version
	]])
end

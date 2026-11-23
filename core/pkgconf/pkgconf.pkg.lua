local version = ZOI.VERSION or "3.0.11"
-- Upstream does not sign releases. The same tarball is published on
-- distfiles.ariadne.space and as a GitHub release asset; the hash matches
-- Gentoo's Manifest and the GitHub release asset digest (sha256).
local sha512 = "4265c81027fea6ff4a193adb232d8e8c73d259743f172b2185457376ed0207e15cae17979dfae61c0306e814b58f575a5437743c474d6efcb40a4b197c7e3575"

metadata({
	name = "pkgconf",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Package compiler and linker metadata toolkit",
	website = "https://github.com/pkgconf/pkgconf",
	license = "ISC",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The pkgconf developers",
		website = "https://github.com/pkgconf/pkgconf",
	},
	bins = {
		"pkgconf",
		"pkg-config",
		"x86_64-pc-linux-gnu-pkg-config",
		"i686-pc-linux-gnu-pkg-config",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "pkg-config", "pkgconfig" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:gcc",
					"pacman:meson",
					"pacman:ninja",
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

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://distfiles.ariadne.space/pkgconf" \
				"https://github.com/pkgconf/pkgconf/releases/download/pkgconf-$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "pkgconf-$VER.tar.xz"
		echo "$SHA512  pkgconf-$VER.tar.xz" | sha512sum -c -
		tar -xf "pkgconf-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	-- Same defaults as a distribution meson build
	cmd(
		[[
		rm -rf build
		meson setup \
			--prefix /usr \
			--libexecdir lib \
			--sbindir bin \
			--buildtype plain \
			--auto-features enabled \
			--wrap-mode nodownload \
			-D b_pie=true \
			"pkgconf-$VER" build
		meson compile -C build
	]],
		opts
	)
end

function package()
	cmd(
		[[
		meson install -C build --destdir "$ROOT"

		for p in "$PKGLUADIR"/files/*.personality; do
			name="$(basename "$p")"
			install -Dm644 "$p" -t "$ROOT/usr/share/pkgconfig/personality.d"
			ln -sf pkgconf "$ROOT/usr/bin/${name%.*}-pkg-config"
		done

		ln -sf pkgconf "$ROOT/usr/bin/pkg-config"
		ln -sf pkgconf.1 "$ROOT/usr/share/man/man1/pkg-config.1"
	]],
		opts
	)

	zlicense("pkgconf-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/pkgconf --version || pkgconf --version
	]])
end

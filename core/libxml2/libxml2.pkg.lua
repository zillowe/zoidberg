local version = ZOI.VERSION or "2.15.4"
local sha512 = "e162ed16ad6fb6c6ef1c40c6bed66a5f76db177fc24410cc261c9ddc6b19e9b003315db67f67cbcadaf08e546f0672de87bf6f297014af50fe544a781647f584"
-- GNOME publishes release tarballs with SHA-256 checksums but no
-- signatures; the hash below was checked against it.

metadata({
	name = "libxml2",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "XML C parser and toolkit",
	website = "https://gitlab.gnome.org/GNOME/libxml2",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The GNOME Project",
		website = "https://gitlab.gnome.org/GNOME/libxml2",
	},
	bins = { "xmllint", "xmlcatalog" },
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
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:icu",
					"pacman:meson",
					"pacman:ninja",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/icu",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libxml2-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://download.gnome.org/sources/libxml2/2.15"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libxml2-$VER.tar.xz"
		echo "$SHA512  libxml2-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "libxml2-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "libxml2-$VER"
		meson setup _build \
			--prefix=/usr \
			--buildtype=plain \
			-Ddefault_library=shared \
			-Dicu=enabled \
			-Dhistory=disabled \
			-Dreadline=disabled \
			-Dpython=disabled \
			-Dlegacy=enabled \
			-Dzlib=enabled
		meson compile -C _build
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libxml2-$VER"
		meson install -C _build --destdir "$ROOT"
	]],
		opts
	)
	zlicense("libxml2-" .. version .. "/Copyright")
end

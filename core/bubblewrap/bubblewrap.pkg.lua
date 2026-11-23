local version = ZOI.VERSION or "0.13.1"
local sha512 =
	"8c8b7e2ec0362e60e88674a1ffb001a9cc7e4107d754ba0db262fe4f14453df2c9a2f0f18a9267f56f0c89d97cdf7f2e244315e86d03b1404477f21e8184dd1c"

metadata({
	name = "bubblewrap",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Unprivileged sandboxing tool",
	website = "https://github.com/containers/bubblewrap",
	license = "LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Bubblewrap developers",
		website = "https://github.com/containers/bubblewrap",
	},
	bins = { "bwrap" },
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
					"pacman:bash-completion",
					"pacman:curl",
					"pacman:docbook-xsl",
					"pacman:gcc",
					"pacman:libcap",
					"pacman:libxslt",
					"pacman:meson",
					"pacman:ninja",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/glibc",
			"zoi:@core/libcap",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/containers/bubblewrap/releases/download/v$VER/bubblewrap-$VER.tar.xz" \
			-o "bubblewrap-$VER.tar.xz"
		echo "$SHA512  bubblewrap-$VER.tar.xz" | sha512sum -c -
		tar -xf "bubblewrap-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	-- assume_kernel: oldest kernel bwrap may run on (major.minor.0). Kept at
	-- the same conservative baseline Arch uses, so older retained kernels
	-- still work.
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
			-D assume_kernel=6.18.0 \
			-D selinux=disabled \
			"bubblewrap-$VER" build
		meson compile -C build
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"
		meson install -C build --destdir "$ROOT"
	]],
		opts
	)

	zlicense("bubblewrap-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/bwrap --version || bwrap --version
	]])
end

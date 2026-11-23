local version = ZOI.VERSION or "1.2.1"
local sha512 =
	"460591287d428c8b5a8a2766b5b424d14501fcda12c7118b8f3cc4bfae44b90ac75ca156557f07b6e22542612724d904533e5f70019be07dbbb604c46f03ab69"

metadata({
	name = "brotli",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Generic-purpose lossless compression algorithm",
	website = "https://github.com/google/brotli",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Google",
		website = "https://github.com/google/brotli",
	},
	bins = { "brotli" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "python" },
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:cmake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:ninja",
					"pacman:python",
					"pacman:python-build",
					"pacman:python-installer",
					"pacman:python-setuptools",
					"pacman:python-wheel",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/glibc",
				},
			},
			python = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/python",
				},
			},
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "brotli-" .. version .. ".tar.gz"
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors "https://github.com/google/brotli/archive/refs/tags/v$VER.tar.gz" -o "brotli-$VER.tar.gz"
		echo "$SHA512  brotli-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "brotli-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "brotli-$VER"
		python -m build --wheel --no-isolation
		cmake -S . -B _build -G Ninja \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DCMAKE_INSTALL_LIBDIR=lib \
			-DBUILD_SHARED_LIBS=ON
		cmake --build _build
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"

	if sub == "main" or sub == "" then
		cmd(
			[[
			cd "brotli-$VER"
			DESTDIR="$ROOT" cmake --install _build
			for man in docs/*.?; do
				install -Dm644 "$man" "$ROOT/usr/share/man/man${man##*.}/${man##*/}"
			done
		]],
			opts
		)
	elseif sub == "python" then
		cmd(
			[[
			cd "brotli-$VER"
			python -m installer --destdir="$ROOT" dist/*.whl
		]],
			opts
		)
	end

	zlicense("brotli-" .. version .. "/LICENSE")
end

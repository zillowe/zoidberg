local version = ZOI.VERSION or "2.1.1"
local sha512 = "60299646ae72e54155a3ca220f00a2b2fee079276a01ff13e30fb6af0d19b07fb4ae539af55e4704ce2081d34c4a3079ef43c0dcb2fe854f835f8441b348f7c5"
-- PyPI sdists are not PGP-signed. The hash matches Gentoo's Manifest, and
-- the file matches the sha256 published by PyPI.

metadata({
	name = "python-cffi",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Foreign Function Interface for Python calling C code",
	website = "https://cffi.readthedocs.org/",
	license = "MIT-0",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Armin Rigo, Maciej Fijalkowski",
		website = "https://cffi.readthedocs.org/",
	},
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
					"pacman:libffi",
					"pacman:pkgconf",
					"pacman:python",
					"pacman:python-build",
					"pacman:python-installer",
					"pacman:python-setuptools",
					"pacman:python-wheel",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libffi",
			"zoi:@core/python",
			"zoi:@core/python-pycparser",
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
				"https://files.pythonhosted.org/packages/source/c/cffi"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "cffi-$VER.tar.gz"
		echo "$SHA512  cffi-$VER.tar.gz" | sha512sum -c -
		tar -xf "cffi-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "cffi-$VER"
		python -m build --wheel --no-isolation
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "cffi-$VER"
		python -m installer --destdir="$ROOT" dist/*.whl
	]],
		opts
	)
	zlicense("cffi-" .. version .. "/LICENSE")
end

function test()
	cmd([[/usr/bin/python3 -c "import cffi, _cffi_backend"]])
end

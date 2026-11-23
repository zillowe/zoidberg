local version = ZOI.VERSION or "2024.8.26"
local sha512 = "62781f2ab84040a13304ce550dd1e943991df152c5f2951281906e837b1659694051a074ff49cd08d5d508e9b70009b56418a4237511c4464c4eba9bda4bccf7"
-- PyPI sdists are not PGP-signed. The hash matches Gentoo's Manifest, and
-- the file matches the sha256 published by PyPI.

metadata({
	name = "python-pefile",
	repo = "core",
	version = version,
	revision = "1",
	description = "Python PE parsing module",
	website = "https://github.com/erocarrera/pefile",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Ero Carrera",
		website = "https://github.com/erocarrera/pefile",
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
					"pacman:curl",
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
			"zoi:@core/python",
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
				"https://files.pythonhosted.org/packages/source/p/pefile"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "pefile-$VER.tar.gz"
		echo "$SHA512  pefile-$VER.tar.gz" | sha512sum -c -
		tar -xf "pefile-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "pefile-$VER"
		python -m build --wheel --no-isolation
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "pefile-$VER"
		python -m installer --destdir="$ROOT" dist/*.whl
	]],
		opts
	)
	zlicense("pefile-" .. version .. "/LICENSE")
end

function test()
	cmd([[/usr/bin/python3 -c "import pefile"]])
end

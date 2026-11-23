local version = ZOI.VERSION or "3.12"
local sha512 = "59ff647f5e902b275b53e9abfad84d1791832be49800ffda82115dd12d0fa780800c163cb12109e247bc6507fa9d58a585edf46e7a614e820c8d0b4335d60a06"
-- PyPI sdists are not PGP-signed. The hash matches Gentoo's Manifest, and
-- the file matches the sha256 published by PyPI.

metadata({
	name = "python-pycparser",
	repo = "core",
	version = version,
	revision = "1",
	description = "C parser and AST generator written in Python",
	website = "https://github.com/eliben/pycparser",
	license = "BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Eli Bendersky",
		website = "https://github.com/eliben/pycparser",
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
				"https://files.pythonhosted.org/packages/source/p/pycparser"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "pycparser-$VER.tar.gz"
		echo "$SHA512  pycparser-$VER.tar.gz" | sha512sum -c -
		tar -xf "pycparser-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "pycparser-$VER"
		python -m build --wheel --no-isolation
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "pycparser-$VER"
		python -m installer --destdir="$ROOT" dist/*.whl
	]],
		opts
	)
	zlicense("pycparser-" .. version .. "/LICENSE")
end

function test()
	cmd([[/usr/bin/python3 -c "import pycparser"]])
end

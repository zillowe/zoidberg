local version = ZOI.VERSION or "50.0.2"
local sha512 = "900fc42e4ab1fe5c513dba1093789a570960dfacb5714582eb2ae98db593756f8c1bbfbf5047cdf902a5a07dd52a857ccca44f15a9025fe9568bf4f310c6c203"
-- PyPI sdists are not PGP-signed (upstream publishes Sigstore provenance
-- only). The hash matches Gentoo's Manifest, and the file matches the
-- sha256 published by PyPI.

metadata({
	name = "python-cryptography",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A package designed to expose cryptographic recipes and primitives to Python developers",
	website = "https://github.com/pyca/cryptography",
	license = "Apache-2.0 OR BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Python Cryptographic Authority",
		website = "https://github.com/pyca/cryptography",
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
					"pacman:clang",
					"pacman:curl",
					"pacman:lld",
					"pacman:llvm",
					"pacman:openssl",
					"pacman:patch",
					"pacman:pkgconf",
					"pacman:python",
					"pacman:python-build",
					"pacman:python-cffi",
					"pacman:python-installer",
					"pacman:python-maturin",
					"pacman:python-setuptools",
					"pacman:python-wheel",
					"pacman:rust",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/glibc",
			"zoi:@core/openssl",
			"zoi:@core/python",
			"zoi:@core/python-cffi",
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
				"https://files.pythonhosted.org/packages/source/c/cryptography"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "cryptography-$VER.tar.gz"
		echo "$SHA512  cryptography-$VER.tar.gz" | sha512sum -c -
		tar -xf "cryptography-$VER.tar.gz"
		cd "cryptography-$VER"
		# Keep raising InvalidTag for failed AEAD tag checks with OpenSSL 4.1
		# (upstream commit e83bbe58, as Arch Linux).
		patch -Np1 -i "$PKGLUADIR/patches/openssl-4.1-invalidtag.patch"
		# Fetch the Rust crates pinned (with checksums) in Cargo.lock now, so
		# the build itself runs offline.
		cargo fetch --locked
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "cryptography-$VER"
		# Cross-language LTO as Arch Linux does
		# (https://github.com/pyca/cryptography/issues/9023).
		export CC=clang
		export RUSTFLAGS="${RUSTFLAGS:-} -Clinker-plugin-lto -Clinker=clang -Clink-arg=-fuse-ld=lld"
		export CARGO_NET_OFFLINE=true
		python -m build --wheel --no-isolation
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "cryptography-$VER"
		python -m installer --destdir="$ROOT" dist/*.whl
	]],
		opts
	)
	zlicense("cryptography-" .. version .. "/LICENSE")
	zlicense("cryptography-" .. version .. "/LICENSE.APACHE")
	zlicense("cryptography-" .. version .. "/LICENSE.BSD")
end

function test()
	cmd([[/usr/bin/python3 -c "import cryptography.hazmat.bindings._rust"]])
end

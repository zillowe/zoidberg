-- The version is the NSS release whose root certificate list is packaged.
local version = ZOI.VERSION or "3.134"
local sha512 = "c615b1fb7be646009c25e1a9d0d1b50833760ad7ff5b717bae58b466937351047841dd4eedb5af3956fdc4c7558276fe969bdde932a0e38869729e124e9677ee"
-- Mozilla publishes NSS release tarballs with SHA-256 checksums but no
-- signatures; the hash below was checked against them when it was recorded.

metadata({
	name = "ca-certificates-mozilla",
	repo = "core",
	version = version,
	revision = "1",
	description = "Mozilla's set of trusted CA certificates",
	website = "https://wiki.mozilla.org/CA",
	license = "MPL-2.0",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Mozilla",
		website = "https://www.mozilla.org",
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
					"pacman:openssl",
					"pacman:python",
				},
			},
		},
	},
	-- No runtime dependencies: this is the data `ca-certificates` (which
	-- depends on this package) turns into certificate bundles.
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
		.. "PKGLUADIR='" .. (loc.PKGLUADIR or ".") .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		tag="NSS_$(printf '%s' "$VER" | tr . _)_RTM"
		curl -sSfL --retry 3 --retry-all-errors \
			"https://ftp.mozilla.org/pub/security/nss/releases/$tag/src/nss-$VER.tar.gz" \
			-o "nss-$VER.tar.gz"
		echo "$SHA512  nss-$VER.tar.gz" | sha512sum -c -
		# Only the root list and its version header are needed.
		mkdir -p certs
		tar -xzf "nss-$VER.tar.gz" -C certs --strip-components=5 \
			"nss-$VER/nss/lib/ckfw/builtins/certdata.txt" \
			"nss-$VER/nss/lib/ckfw/builtins/nssckbi.h"
		rm "nss-$VER.tar.gz"
	]])
end

function build()
	-- certdata2pem.py and bundle.sh come from Fedora's ca-certificates
	-- packaging, by way of Arch Linux's nss package.
	sh([[
		cd certs
		python3 "$PKGLUADIR/certdata2pem.py"
		cd ..
		sh "$PKGLUADIR/bundle.sh"
		[ -s ca-bundle.trust.p11-kit ]
	]])
end

function package()
	sh([[
		install -Dm644 ca-bundle.trust.p11-kit \
			"$ROOT/usr/share/ca-certificates/trust-source/mozilla.trust.p11-kit"
	]])
end

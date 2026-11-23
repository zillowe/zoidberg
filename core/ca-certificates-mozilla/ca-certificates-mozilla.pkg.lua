-- The version is the NSS release whose root certificate list is packaged.
local version = ZOI.VERSION or "3.134"
local sha512 =
	"c615b1fb7be646009c25e1a9d0d1b50833760ad7ff5b717bae58b466937351047841dd4eedb5af3956fdc4c7558276fe969bdde932a0e38869729e124e9677ee"

metadata({
	name = "ca-certificates-mozilla",
	repo = "core",
	version = version,
	revision = "2",
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
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
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
		# NSS's license file (notes plus the full MPL-2.0 text).
		tar -xzf "nss-$VER.tar.gz" "nss-$VER/nss/COPYING"
		rm "nss-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	-- certdata2pem.py and bundle.sh come from Fedora's ca-certificates
	-- packaging, by way of Arch Linux's nss package.
	cmd(
		[[
		cd certs
		python3 "$PKGLUADIR/files/certdata2pem.py"
		cd ..
		sh "$PKGLUADIR/files/bundle.sh"
		[ -s ca-bundle.trust.p11-kit ]
	]],
		opts
	)
end

function package()
	cmd(
		[[
		install -Dm644 ca-bundle.trust.p11-kit \
			"$ROOT/usr/share/ca-certificates/trust-source/mozilla.trust.p11-kit"
	]],
		opts
	)

	zlicense("nss-" .. version .. "/nss/COPYING")
end

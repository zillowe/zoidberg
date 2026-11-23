local version = ZOI.VERSION or "1.1.7"
local sha512 = "4dc900ad6e74c4ce532df974287bd3d5382ccabcee9e61b7639071abae70c215a8dea04d1f5af6f0f431e5717bd98db12dc858b00b51f284a17b488ef648b73d"
-- Release signing key (Netfilter Core Team), matches Arch's validpgpkeys.
local signing_key = "8C5F7146A1757A65E2422A94D70D1A666ACF2B21"

metadata({
	name = "nftables",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Netfilter tables userspace tools",
	website = "https://www.netfilter.org/projects/nftables/",
	license = "GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Netfilter Project",
		website = "https://www.netfilter.org",
	},
	bins = {
		"nft",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/nftables.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:bison",
					"pacman:curl",
					"pacman:flex",
					"pacman:gcc",
					"pacman:gmp",
					"pacman:jansson",
					"pacman:libmnl",
					"pacman:libnftnl",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:readline",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/gmp",
			"zoi:@core/jansson",
			"zoi:@core/libmnl",
			"zoi:@core/libnftnl",
			"zoi:@core/readline",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "nftables-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.netfilter.org/projects/nftables/files"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "nftables-$VER.tar.xz"
		fetch "nftables-$VER.tar.xz.sig"
		echo "$SHA512  nftables-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "nftables-$VER.tar.xz"]], opts)
end

function build()
	-- Options as Arch (minus --disable-python, which 1.1.7's configure no
	-- longer has; xtables translation is disabled explicitly). The release
	-- tarball ships the man pages prebuilt, so asciidoc is not needed. Arch
	-- builds the Python bindings separately as a wheel; they are skipped
	-- here (no Python runtime dependency).
	cmd(
		[[
		cd "nftables-$VER"
		./configure \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--sysconfdir=/usr/share \
			--disable-static \
			--with-json \
			--with-cli=readline \
			--without-xtables \
			--disable-debug
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "nftables-$VER" DESTDIR="$ROOT" install
		# Basic safe firewall config and service, from Arch's package.
		install -Dm644 "$PKGLUADIR/files/nftables.conf" "$ROOT/etc/nftables.conf"
		install -Dm644 "$PKGLUADIR/files/nftables.service" "$ROOT/usr/lib/systemd/system/nftables.service"
	]],
		opts
	)
	zlicense("nftables-" .. version .. "/COPYING")
end

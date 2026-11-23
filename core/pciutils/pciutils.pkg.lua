local version = ZOI.VERSION or "3.15.0"
local sha512 = "5869372d4e19730e5c634490aed7379c8b5d461e9e745d7bc67495dc9e51dfe3a432ef594a9d67df1ac466ac1e91548aa432252d9263b116bdada5398a05fd97"
-- Release signing key (Martin Mareš), as listed in the kernel.org keyring.
local signing_key = "C466A56CADA981F4297D20C31F3D0761D9B65F0B"

metadata({
	name = "pciutils",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "PCI bus configuration space access library and tools (lspci, setpci)",
	website = "https://mj.ucw.cz/sw/pciutils/",
	license = "GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Martin Mares",
		website = "https://mj.ucw.cz/sw/pciutils/",
	},
	bins = {
		"lspci",
		"setpci",
		"update-pciids",
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
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:kmod",
					"pacman:make",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/hwdata",
			"zoi:@core/kmod",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "pciutils-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/software/utils/pciutils" \
				"https://www.kernel.org/pub/software/utils/pciutils" \
				"https://mirrors.kernel.org/pub/software/utils/pciutils"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "pciutils-$VER.tar.xz"
		fetch "pciutils-$VER.tar.sign"
		echo "$SHA512  pciutils-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	-- kernel.org signs the uncompressed tar.
	cmd([[xz -dk "pciutils-$VER.tar.xz"]], opts)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "pciutils-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "pciutils-$VER"

		make OPT="${CFLAGS}" ZLIB=no SHARED=yes \
			PREFIX=/usr \
			SBINDIR=/usr/bin \
			SHAREDIR=/usr/share/hwdata \
			MANDIR=/usr/share/man \
			-j"$(nproc)" all
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "pciutils-$VER" SHARED=yes \
			PREFIX=/usr \
			SBINDIR=/usr/bin \
			SHAREDIR=/usr/share/hwdata \
			MANDIR=/usr/share/man \
			DESTDIR="$ROOT" install install-lib

		# Remove bundled pci.ids as hwdata package provides it
		rm -rf "$ROOT"/usr/share/hwdata
	]],
		opts
	)

	zlicense("pciutils-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/lspci --version || lspci --version || true
	]])
end

local version = ZOI.VERSION or "3.15.0"
local tag = "v" .. version
local git_url = "https://git.kernel.org/pub/scm/utils/pciutils/pciutils.git"

metadata({
	name = "pciutils",
	repo = "core",
	version = version,
	revision = "3",
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
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:git",
					"pacman:kmod",
					"pacman:make",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d pciutils ]; then
			git clone --depth 1 --branch "%s" "%s" pciutils
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd pciutils

		make OPT="${CFLAGS}" ZLIB=no SHARED=yes \
			PREFIX=/usr \
			SBINDIR=/usr/bin \
			SHAREDIR=/usr/share/hwdata \
			MANDIR=/usr/share/man \
			-j"$(nproc)" all
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"

		make -C pciutils SHARED=yes \
			PREFIX=/usr \
			SBINDIR=/usr/bin \
			SHAREDIR=/usr/share/hwdata \
			MANDIR=/usr/share/man \
			DESTDIR="$ROOT" install install-lib

		# Remove bundled pci.ids as hwdata package provides it
		rm -rf "$ROOT"/usr/share/hwdata
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/lspci --version || lspci --version || true
	]])
end

local version = ZOI.VERSION or "2026.11"

metadata({
	name = "base",
	repo = "core",
	version = version,
	revision = "8",
	description = "Minimal userland for Parlex Linux and isolated (--pure) build roots",
	website = "https://zillowe.qzz.io/docs/parlex/linux",
	license = "Apache-2.0",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	type = "collection",
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "dev", "docs" },
	main_subs = { "main" },
})

dependencies({
	runtime = {
		sub_packages = {
			main = {
				required = {
					-- Foundational
					"zoi:@core/filesystem",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/glibc",
					"zoi:@core/bash",
					-- POSIX tools
					"zoi:@core/coreutils",
					"zoi:@core/file",
					"zoi:@core/findutils",
					"zoi:@core/gawk",
					"zoi:@core/grep",
					"zoi:@core/procps-ng",
					"zoi:@core/sed",
					"zoi:@core/tar",
					-- Standard Linux toolset
					"zoi:@core/gettext",
					"zoi:@core/pciutils",
					"zoi:@core/psmisc",
					"zoi:@core/shadow",
					"zoi:@core/util-linux",
					-- Time zones and console keymaps (system.lua timezone/keymap)
					"zoi:@core/tzdata",
					"zoi:@core/kbd",
					"zoi:@core/bzip2",
					"zoi:@core/gzip",
					"zoi:@core/xz",
					-- Pager (systemctl, journalctl, git)
					"zoi:@core/less",
					-- Zoi Core
					"zoi:@core/zoi",
					-- Networking
					"zoi:@core/iputils",
					"zoi:@core/iproute2",
					-- POSIX utilities beyond Arch's base, small enough for
					-- build roots: diff/cmp, which, ed, bc (also needed by
					-- kernel builds) and vi/ex.
					"zoi:@core/diffutils",
					"zoi:@core/which",
					"zoi:@core/ed",
					"zoi:@core/bc",
					"zoi:@core/vi",
				},
			},
			-- man and its formatter (man-db, groff); optional, as headless
			-- systems rarely need them.
			docs = {
				required = {
					"zoi:@core/base:main",
					"zoi:@core/man-db",
				},
			},
			dev = {
				required = {
					"zoi:@core/base:main",
					"zoi:@core/autoconf",
					"zoi:@core/automake",
					"zoi:@core/binutils",
					"zoi:@core/bison",
					"zoi:@core/debugedit",
					"zoi:@core/fakeroot",
					"zoi:@core/flex",
					"zoi:@core/gcc",
					"zoi:@core/groff",
					"zoi:@core/libtool",
					"zoi:@core/m4",
					"zoi:@core/make",
					"zoi:@core/patch",
					"zoi:@core/pkgconf",
					"zoi:@core/texinfo",
				},
			},
		},
	},
})

function prepare()
	-- Meta-package / collection definition
end

function package(args)
	-- Meta-package installs no distinct files directly
end

function test()
	-- Meta-package verified via dependency satisfaction
end

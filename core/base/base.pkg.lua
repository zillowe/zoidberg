local version = ZOI.VERSION or "2026.8"

-- thank you arch <3

metadata({
	name = "base",
	repo = "core",
	version = version,
	revision = "1",
	description = "Minimal package set to define a basic Parlex Linux installation",
	website = "https://zillowe.qzz.io/docs/zds/zoios",
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
	platforms = { "linux" },
	type = "collection",
	zoios = true,
	sub_packages = { "main", "dev" },
	main_subs = { "main" },
})

dependencies({
	runtime = {
		sub_packages = {
			main = {
				options = {
					{
						name = "init system",
						desc = "init provider for your system",
						all = false,
						depends = {
							"zoi:@core/systemd",
							"zoi:@core/openrc",
						},
					},
					{
						name = "kernel",
						desc = "linux kernel for your system",
						all = false,
						depends = {
							"zoi:@core/linux",
							"zoi:@core/linux-hardened",
						},
					},
					{
						name = "bootloader",
						desc = "bootloader for your system",
						all = false,
						depends = {
							"zoi:@core/grub",
							"zoi:@core/systemd-boot",
							"zoi:@core/limine",
						},
					},
					{
						name = "privilege escalator",
						desc = "sudo or doas for your system",
						all = false,
						depends = {
							"zoi:@core/sudo",
							"zoi:@core/doas",
						},
					},
				},
				required = {
					-- Foundational
					"zoi:@core/filesystem",
					"zoi:@core/gcc:libgcc",
					"zoi:@core/glibc",
					"zoi:@core/bash",
					-- Booting
					"zoi:@core/dracut",
					"zoi:@core/linux-firmware",
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
					"zoi:@core/bzip2",
					"zoi:@core/gzip",
					"zoi:@core/xz",
					-- Zoi Core
					"zoi:@core/zoi",
					"zoi:@core/zoid",
					-- Networking
					"zoi:@core/iputils",
					"zoi:@core/iproute2",
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
					"zoi:@core/which",
				},
			},
		},
	},
})

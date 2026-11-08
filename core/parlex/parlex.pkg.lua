local version = ZOI.VERSION or "2026.11"

metadata({
	name = "parlex",
	repo = "core",
	version = version,
	revision = "1",
	description = "Package set for a bootable Parlex Linux installation",
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
})

dependencies({
	runtime = {
		required = {
			-- Minimal userland
			"zoi:@core/base",
			-- Kernel
			"zoi:@core/linux",
			"zoi:@core/linux-firmware",
			-- Booting
			"zoi:@core/dracut",
			"zoi:@core/grub",
			-- Init
			"zoi:@core/systemd",
			-- Privilege escalation
			"zoi:@core/sudo",
			-- Zoi daemon
			"zoi:@core/zoid",
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

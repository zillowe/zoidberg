local version = ZOI.VERSION or "2026.11"

metadata({
	name = "parlex",
	repo = "core",
	version = version,
	revision = "6",
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
			-- Booting
			"zoi:@core/dracut",
			"zoi:@core/grub",
			-- Init
			"zoi:@core/systemd",
			-- /usr/bin/init (the kernel's default init), halt, poweroff,
			-- reboot and shutdown, as Arch's base pulls systemd-sysvcompat.
			"zoi:@core/systemd:sysvcompat",
			-- Privilege escalation
			"zoi:@core/sudo",
			-- Zoi daemon
			"zoi:@core/zoi:zoid",
		},
		-- Firmware depends on the hardware, so the user picks it (Zoi prompts
		-- for optional dependencies). A virtual machine needs none; real
		-- hardware usually needs its vendors' firmware, or the default set.
		optional = {
			"zoi:@core/linux-firmware:main:the default set (all common vendors)",
			"zoi:@core/linux-firmware:amd_ucode:AMD CPU microcode",
			"zoi:@core/linux-firmware:intel:firmware for Intel Wi-Fi, Bluetooth, GPUs and CPU-integrated devices",
			"zoi:@core/linux-firmware:amdgpu:firmware for AMD Radeon GPUs (amdgpu driver)",
			"zoi:@core/linux-firmware:radeon:firmware for older AMD/ATI GPUs (radeon driver)",
			"zoi:@core/linux-firmware:nvidia:firmware for NVIDIA GPUs (nouveau, nova)",
			"zoi:@core/linux-firmware:realtek:firmware for Realtek network, Wi-Fi and Bluetooth",
			"zoi:@core/linux-firmware:atheros:firmware for Qualcomm Atheros Wi-Fi and Bluetooth",
			"zoi:@core/linux-firmware:broadcom:firmware for Broadcom and Cypress network adapters",
			"zoi:@core/linux-firmware:mediatek:firmware for MediaTek and Ralink Wi-Fi and Bluetooth",
			"zoi:@core/linux-firmware:amd:firmware for non-GPU AMD devices (NPU, TEE)",
			"zoi:@core/linux-firmware:cirrus:firmware for Cirrus Logic audio",
			"zoi:@core/linux-firmware:ti:firmware for Texas Instruments audio and connectivity",
			"zoi:@core/linux-firmware:other:firmware for other devices",
			"zoi:@core/linux-firmware:marvell:firmware for Marvell devices",
			"zoi:@core/linux-firmware:qcom:firmware for Qualcomm SoCs",
			"zoi:@core/linux-firmware:qlogic:firmware for QLogic adapters",
			"zoi:@core/linux-firmware:mellanox:firmware for Mellanox Spectrum switches",
			"zoi:@core/linux-firmware:nfp:firmware for Netronome Flow Processors",
			"zoi:@core/linux-firmware:liquidio:firmware for Cavium LiquidIO adapters",
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

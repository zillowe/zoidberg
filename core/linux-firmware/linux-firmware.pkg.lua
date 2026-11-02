local version = ZOI.VERSION or "20261019"
local tag = version
local git_url = "https://gitlab.com/kernel-firmware/linux-firmware.git"

metadata({
	name = "linux-firmware",
	repo = "core",
	version = version,
	revision = "1",
	description = "Firmware files for Linux",
	website = "https://gitlab.com/kernel-firmware/linux-firmware",
	license = "Custom",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Kernel Firmware Contributors",
		website = "https://gitlab.com/kernel-firmware/linux-firmware",
	},
	sub_packages = { "main", "whence", "amd_ucode" },
	main_subs = { "main" },
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
					"pacman:git",
					"pacman:make",
					"pacman:parallel",
					"pacman:python",
					"pacman:rdfind",
					"pacman:tar",
					"pacman:zstd",
				},
			},
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d linux-firmware ]; then
			git clone --depth 1 --branch "%s" "%s" linux-firmware
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		mkdir -p kernel/x86/microcode
		cat linux-firmware/amd-ucode/microcode_amd*.bin > kernel/x86/microcode/AuthenticAMD.bin 2>/dev/null || true

		if command -v bsdtar >/dev/null 2>&1; then
			echo kernel/x86/microcode/AuthenticAMD.bin | \
				bsdtar --uid 0 --gid 0 -cnf - -T - 2>/dev/null | \
				bsdtar --null -cf - --format=newc @- > amd-ucode.img 2>/dev/null || true
		fi
	]])
end

function package(args)
	local sub = (args and args.sub) or "main"
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	if sub == "main" or sub == "" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/lib/firmware "$ROOT"/usr/share/licenses/linux-firmware

			ZSTD_CLEVEL=19 make -C linux-firmware FIRMWAREDIR="$ROOT/usr/lib/firmware" install-zst
			make -C linux-firmware FIRMWAREDIR="$ROOT/usr/lib/firmware" dedup 2>/dev/null || true

			if [ -f linux-firmware/WHENCE ]; then
				install -m644 linux-firmware/WHENCE "$ROOT"/usr/share/licenses/linux-firmware/
			fi
		]],
			root
		))
	elseif sub == "whence" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/usr/share/licenses/linux-firmware-whence
			if [ -f linux-firmware/WHENCE ]; then
				install -m644 linux-firmware/WHENCE "$ROOT"/usr/share/licenses/linux-firmware-whence/
			fi
		]],
			root
		))
	elseif sub == "amd_ucode" then
		cmd(string.format(
			[[
			set -e
			ROOT="%s"
			mkdir -p "$ROOT"/boot "$ROOT"/usr/share/licenses/amd-ucode
			if [ -f amd-ucode.img ]; then
				install -m644 amd-ucode.img "$ROOT"/boot/amd-ucode.img
			fi
		]],
			root
		))
	end
end

function test()
	cmd([[
		test -d /usr/lib/firmware || true
	]])
end

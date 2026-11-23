local version = ZOI.VERSION or "20261019"
local sha512 = "725bfcc57def709e43dcd89683e1a663c2d221e3d34da58ffcbf8af3b9c6da2b763739ec8fe0c2ece2620c71b2556b97f93e784c2d3f7c320b98bf35338e6aed"
-- Release signing key (Josh Boyer), from kernel.org's pgpkeys repository
-- (keys/A31B6BD72486CFD6.asc), listed in Arch Linux's validpgpkeys.
local signing_key = "4CDE8575E547BF835FE15807A31B6BD72486CFD6"

metadata({
	name = "linux-firmware",
	repo = "core",
	version = version,
	revision = "5",
	-- Firmware blobs can be ELF files for other processors (DSPs, Wi-Fi and
	-- GPU microcontrollers) and must reach the device byte-for-byte.
	debug = { strip = "none" },
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
	zsa = false,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:make",
					"pacman:parallel",
					"pacman:rdfind",
					"pacman:tar",
					"pacman:xz",
					"pacman:zstd",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	-- prepare() runs again for every sub-package in the same build
	-- directory; download, verify and unpack the 672 MB tarball only once.
	if UTILS.FS.exists(BUILD_DIR .. "/linux-firmware-" .. version .. "/.zoi-prepared") then
		return
	end
	local tarball = "linux-firmware-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://cdn.kernel.org/pub/linux/kernel/firmware" \
				"https://mirrors.edge.kernel.org/pub/linux/kernel/firmware" \
				"https://www.kernel.org/pub/linux/kernel/firmware"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "linux-firmware-$VER.tar.xz"
		fetch "linux-firmware-$VER.tar.sign"
		echo "$SHA512  linux-firmware-$VER.tar.xz" | sha512sum -c -
		# kernel.org signs the uncompressed tar.
		xz -dk "linux-firmware-$VER.tar.xz"
	]],
		opts
	)
	local tar = tarball:gsub("%.xz$", "")
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tar, tar .. ".sign", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "linux-firmware-$VER.tar"
		rm -f "linux-firmware-$VER.tar"
		touch "linux-firmware-$VER/.zoi-prepared"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		mkdir -p kernel/x86/microcode
		# Firmware tags without AMD microcode leave an empty file.
		cat "linux-firmware-$VER"/amd-ucode/microcode_amd*.bin > kernel/x86/microcode/AuthenticAMD.bin 2>/dev/null || true

		# The early-load image is optional: it needs bsdtar (libarchive).
		if command -v bsdtar >/dev/null 2>&1; then
			echo kernel/x86/microcode/AuthenticAMD.bin | \
				bsdtar --uid 0 --gid 0 -cnf - -T - 2>/dev/null | \
				bsdtar --null -cf - --format=newc @- > amd-ucode.img 2>/dev/null || true
		fi
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"
	local src = "linux-firmware-" .. version

	if sub == "main" or sub == "" then
		cmd(
			[[
			mkdir -p "$ROOT"/usr/lib/firmware

			ZSTD_CLEVEL=19 make -C "linux-firmware-$VER" FIRMWAREDIR="$ROOT/usr/lib/firmware" install-zst
			# De-duplication (symlinking identical files) only saves space.
			make -C "linux-firmware-$VER" FIRMWAREDIR="$ROOT/usr/lib/firmware" dedup 2>/dev/null || true
		]],
			opts
		)
		-- WHENCE lists each file's license; the texts live in LICENSES/
		-- (LICENCE.*, LICENSE.*, NOTICE.*).
		zlicense(src .. "/WHENCE")
		zlicense(src .. "/LICENSES")
	elseif sub == "whence" then
		zlicense(src .. "/WHENCE")
	elseif sub == "amd_ucode" then
		cmd(
			[[
			mkdir -p "$ROOT"/boot
			if [ -f amd-ucode.img ]; then
				install -m644 amd-ucode.img "$ROOT"/boot/amd-ucode.img
			fi
		]],
			opts
		)
		zlicense(src .. "/LICENSES/LICENSE.amd-ucode")
	end
end

function test()
	cmd([[
		test -d /usr/lib/firmware || true
	]])
end

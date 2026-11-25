local version = ZOI.VERSION or "20261019"
local sha512 = "725bfcc57def709e43dcd89683e1a663c2d221e3d34da58ffcbf8af3b9c6da2b763739ec8fe0c2ece2620c71b2556b97f93e784c2d3f7c320b98bf35338e6aed"
-- Release signing key (Josh Boyer), from kernel.org's pgpkeys repository
-- (keys/A31B6BD72486CFD6.asc), listed in Arch Linux's validpgpkeys.
local signing_key = "4CDE8575E547BF835FE15807A31B6BD72486CFD6"

metadata({
	name = "linux-firmware",
	repo = "core",
	version = version,
	revision = "6",
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
	-- Split by vendor as Arch Linux does: `main` is the default set (it
	-- installs nothing itself and depends on the vendor sub-packages), so a
	-- system can install only the firmware its hardware needs.
	sub_packages = {
		"main",
		"whence",
		"other",
		"amd_ucode",
		"amd",
		"amdgpu",
		"atheros",
		"broadcom",
		"cirrus",
		"intel",
		"liquidio",
		"marvell",
		"mediatek",
		"mellanox",
		"nfp",
		"nvidia",
		"qcom",
		"qlogic",
		"radeon",
		"realtek",
		"ti",
	},
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
					"pacman:libarchive",
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
	runtime = {
		sub_packages = {
			main = {
				required = {
					"zoi:@core/linux-firmware:amd",
					"zoi:@core/linux-firmware:amdgpu",
					"zoi:@core/linux-firmware:atheros",
					"zoi:@core/linux-firmware:broadcom",
					"zoi:@core/linux-firmware:cirrus",
					"zoi:@core/linux-firmware:intel",
					"zoi:@core/linux-firmware:mediatek",
					"zoi:@core/linux-firmware:nvidia",
					"zoi:@core/linux-firmware:other",
					"zoi:@core/linux-firmware:radeon",
					"zoi:@core/linux-firmware:realtek",
					"zoi:@core/linux-firmware:ti",
				},
				optional = {
					"zoi:@core/linux-firmware:liquidio:firmware for Cavium LiquidIO server adapters",
					"zoi:@core/linux-firmware:marvell:firmware for Marvell devices",
					"zoi:@core/linux-firmware:mellanox:firmware for Mellanox Spectrum switches",
					"zoi:@core/linux-firmware:nfp:firmware for Netronome Flow Processors",
					"zoi:@core/linux-firmware:qcom:firmware for Qualcomm SoCs",
					"zoi:@core/linux-firmware:qlogic:firmware for QLogic devices",
				},
			},
			other = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			amd = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			amdgpu = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			atheros = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			broadcom = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			cirrus = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			intel = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			liquidio = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			marvell = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			mediatek = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			mellanox = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			nfp = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			nvidia = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			qcom = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			qlogic = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			radeon = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			realtek = {
				required = { "zoi:@core/linux-firmware:whence" },
			},
			ti = {
				required = { "zoi:@core/linux-firmware:whence" },
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

-- Which firmware goes to which vendor sub-package: Arch Linux's split
-- (patterns relative to /usr/lib/firmware). Whatever no pattern matches
-- belongs to `other`.
local split = {
	amd_ucode = "amd-ucode",
	amd = "amd amdnpu amdtee",
	amdgpu = "amdgpu",
	atheros = "ar[0-9]* ath* carl9170* htc_* qca wil6210*",
	broadcom = "bnx2* brcm cypress tigon",
	cirrus = "cirrus cs42l43* sdca",
	intel = "e100 hfi1_* i915 intel isci iwlwifi* ixp4xx qat_* xe */ish",
	liquidio = "liquidio",
	marvell = "libertas mwl8k mwlwifi mrvl",
	mediatek = "mediatek mt7* rt[237]*",
	mellanox = "mellanox",
	nfp = "netronome",
	nvidia = "nvidia",
	qcom = "qcom a300_*",
	qlogic = "qlogic qed ql2???_* cbfw-* ctfw-* ct2fw-*",
	radeon = "radeon",
	realtek = "realtek rtlwifi rtw8* rtl_*",
	ti = "ti_* ti ti-connectivity tas* INT8* TAS2* TI* TX* ????-*-0x?.*",
}

function build()
	-- build() runs for every sub-package in the same build directory:
	-- install and split the firmware only once.
	if UTILS.FS.exists(BUILD_DIR .. "/split/.zoi-split") then
		return
	end
	local picks = {}
	for sub, patterns in pairs(split) do
		-- Quoted, so the patterns are expanded inside pick(), in the
		-- firmware directory.
		local quoted = {}
		for pattern in patterns:gmatch("%S+") do
			table.insert(quoted, "'" .. pattern .. "'")
		end
		table.insert(picks, "pick " .. sub .. " " .. table.concat(quoted, " "))
	end
	table.sort(picks)
	cmd(
		[[
		# AMD CPU microcode as an early-load image for the initramfs.
		mkdir -p kernel/x86/microcode
		cat "linux-firmware-$VER"/amd-ucode/microcode_amd*.bin \
			> kernel/x86/microcode/AuthenticAMD.bin
		if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
			touch -d "@$SOURCE_DATE_EPOCH" kernel/x86/microcode/AuthenticAMD.bin
		fi
		echo kernel/x86/microcode/AuthenticAMD.bin |
			bsdtar --uid 0 --gid 0 -cnf - -T - |
			bsdtar --null -cf - --format=newc @- > amd-ucode.img

		rm -rf split
		FW="$PWD/split/other/usr/lib/firmware"
		ZSTD_CLEVEL=19 make -C "linux-firmware-$VER" FIRMWAREDIR="$FW" install-zst

		# pick SUB PATTERN...: move matching firmware from `other` to SUB.
		pick() {
			sub="$1"
			shift
			cd "$FW"
			for pattern in "$@"; do
				for f in $pattern; do
					[ -e "$f" ] || [ -L "$f" ] || continue
					mkdir -p "$(dirname "../../../../$sub/usr/lib/firmware/$f")"
					mv "$f" "../../../../$sub/usr/lib/firmware/$f"
				done
			done
			cd - >/dev/null
		}
		]] .. table.concat(picks, "\n\t\t") .. [[


		# Symlink identical files within each sub-package.
		for dir in split/*/usr/lib/firmware; do
			make -C "linux-firmware-$VER" FIRMWAREDIR="$PWD/$dir" dedup
		done
		install -Dm644 amd-ucode.img split/amd_ucode/boot/amd-ucode.img
		touch split/.zoi-split
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"
	local src = "linux-firmware-" .. version

	if UTILS.FS.exists(BUILD_DIR .. "/split/" .. sub) then
		cmd([[cp -a "split/$SUB"/. "$ROOT/"]], { check = true, env = { SUB = sub } })
	end

	if sub == "amd_ucode" then
		zlicense(src .. "/LICENSES/LICENSE.amd-ucode")
	else
		-- WHENCE names each file's license; the texts ship with `whence`,
		-- which every firmware sub-package depends on.
		zlicense(src .. "/WHENCE")
		if sub == "whence" then
			zlicense(src .. "/LICENSES")
		end
	end
end

function test()
	cmd(
		[[
		for sub in amdgpu intel other; do
			test -d "split/$sub/usr/lib/firmware"
		done
		test -s split/amd_ucode/boot/amd-ucode.img
	]],
		{ check = true }
	)
	return true
end

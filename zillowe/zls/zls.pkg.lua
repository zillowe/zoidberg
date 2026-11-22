local version = ZOI.VERSION or "1.1.1"

-- local function get_zig_target()
-- 	local os = SYSTEM.OS
-- 	local arch = SYSTEM.ARCH
-- 	if arch == "amd64" then
-- 		arch = "x86_64"
-- 	elseif arch == "arm64" then
-- 		arch = "aarch64"
-- 	end
-- 	return arch .. "-" .. os
-- end

metadata({
	name = "zls",
	repo = "zillowe",
	version = version,
	revision = "22",
	description = "Stateless link shortener inspired by ha.mr.",
	website = "https://zillowe.qzz.io/docs/zds/zls",
	git = "https://gitlab.com/zillowe/zillwen/zusty/zls",
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
	license = "Apache-2.0",
	bins = { "zls" },
	types = { "source" },
	tags = { "zillowe", "cli", "link-shortner" },
	platforms = { "linux-amd64" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:zig",
					"pacman:git",
				},
			},
		},
	},
})

function prepare()
	if BUILD_TYPE == "source" then
		cmd("git clone --depth 1 --branch " .. "v" .. version .. " " .. PKG.git .. " source")
		-- cmd("cd " .. BUILD_DIR .. "/source && zig build --release=small -Dtarget=" .. get_zig_target())
	end
end

function build()
	if BUILD_TYPE == "source" then
		cmd("cd source")
		cmd("zig build -Doptimize=ReleaseFast -Dtarget=x86_64-linux")
	end
end

function package()
	if BUILD_TYPE == "source" then
		local bin_name = "zls"
		zcp("source/zig-out/bin/" .. bin_name, "${pkgstore}/bin/" .. bin_name)
	end
end

function uninstall() end

local version = "1.29.15"
local tag = "Prod-Release-" .. version
local release = "https://gitlab.com/zillowe/zillwen/zusty/zoi/-/releases/" .. tag .. "/downloads"
-- Zillowe release signing key (79590A44041642E9), as published at
-- https://zillowe.pages.dev/keys/zillowe-main.asc.
local function public_key()
	return LOCATION.PKGLUADIR .. "/keys/pgp/B2DF6A70FAEBAF2F43D9D68B79590A44041642E9.asc"
end

local function archive_name()
	local os, arch = SYSTEM.OS, SYSTEM.ARCH

	if arch == "386" then
		error("zoid has no pre-built 32-bit x86 artifact; the release pipeline " .. "builds amd64 and arm64 only")
	end

	return "zoid-" .. os .. "-" .. arch .. ".tar.zst"
end

local function published_sha512(name)
	local out, _, _ = cmd("cat checksums.txt")
	if not out or out == "" then
		return nil
	end

	for line in out:gmatch("[^\r\n]+") do
		local hash, entry = line:match("^(%x+)%s+%.?/(.+)$")
		if hash and entry == name then
			return hash
		end
	end

	return nil
end

local function fetch_verified()
	local archive = archive_name()

	UTILS.DOWNLOAD(release .. "/checksums.txt", "checksums.txt")

	local sha = published_sha512(archive)
	if not sha then
		error(
			"release "
				.. tag
				.. " publishes no sha512 for "
				.. archive
				.. "; either the artifact is missing or the manifest is "
				.. "malformed"
		)
	end

	UTILS.DOWNLOAD(release .. "/" .. archive, archive, "sha512-" .. sha)
	UTILS.DOWNLOAD(release .. "/" .. archive .. ".asc", archive .. ".asc")

	if not verifySignature(archive, archive .. ".asc", public_key()) then
		error(
			"the signature on " .. archive .. " is not valid for the Zillowe " .. "release key; refusing to install it"
		)
	end

	return archive
end

metadata({
	name = "zoid",
	repo = "core",
	version = version,
	revision = "1",
	description = "ZoiOS privileged system daemon",
	website = "https://zillowe.qzz.io/zds/zoi",
	git = "https://gitlab.com/zillowe/zillwen/zusty/zoi.git",
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
	bins = { "zoid" },
	types = { "pre-compiled" },
	scope = "system",
	scopes = { "system" },
	zoios = true,
	platforms = { "linux-amd64" },
	tags = { "zillowe", "zoios", "daemon", "systemd" },
})

dependencies({
	runtime = {
		required = {
			"zoi:@core/zoi",
		},
	},
})

function prepare()
	local archive = fetch_verified()
	local build_dir = BUILD_DIR or (LOCATION and LOCATION.BUILDDIR) or "."
	UTILS.EXTRACT(build_dir .. "/" .. archive, "source")
	UTILS.DOWNLOAD(release .. "/zoid.8", "zoid.8")
	UTILS.DOWNLOAD(release .. "/LICENSE", "LICENSE")
end

function package()
	zcp("source/zoid", "${usrroot}/usr/bin/zoid")
	zcp("${pkgluadir}/zoid.service", "${usrroot}/usr/lib/systemd/system/zoid.service")
	-- Restarts a running zoid after an update so the new daemon is loaded
	zcp("${pkgluadir}/hooks/zoid-restart.hook.yaml", "${pkgstore}/hooks/zoid-restart.hook.yaml")
	zman("zoid.8")
	zlicense("LICENSE")
end

function test()
	local bin = LOCATION.STAGINGDIR .. "/data/usrroot/usr/bin/zoid"

	local _, _, code = cmd(bin .. " --version")
	return code == 0
end

function uninstall() end

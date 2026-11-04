local version = "1.29.3"
local tag = "Prod-Release-" .. version
local release = "https://gitlab.com/zillowe/zillwen/zusty/zoi/-/releases/" .. tag .. "/downloads"
local public_key = "https://zillowe.pages.dev/keys/zillowe-main.asc"

local function platform()
	local os, arch = SYSTEM.OS, SYSTEM.ARCH
	if arch == "386" then
		error("zoi has no pre-built 32-bit x86 artifact; the release pipeline " .. "builds amd64 and arm64 only")
	end

	return os, arch
end

local function archive_name()
	local os, arch = platform()
	return "zoi-" .. os .. "-" .. arch .. (os == "windows" and ".zip" or ".tar.zst")
end

local function binary_name()
	return SYSTEM.OS == "windows" and "zoi.exe" or "zoi"
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

	if not verifySignature(archive, archive .. ".asc", public_key) then
		error(
			"the signature on " .. archive .. " is not valid for the Zillowe " .. "release key; refusing to install it"
		)
	end

	return archive
end

metadata({
	name = "zoi",
	repo = "core",
	version = version,
	revision = "2",
	description = "Advanced Package Manager & Environment Orchestrator",
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
	bins = { "zoi" },
	types = { "pre-compiled" },
	scope = "system",
	scopes = { "system" },
	zoios = true,
	platforms = { "linux-amd64" },
	tags = { "zillowe", "package-manager", "cli" },
})

dependencies({
	runtime = {
		required = {
			"zoi:@core/git",
			"zoi:@core/gnupg",
			"zoi:@core/openssl:lib",
		},
		optional = {
			"zoi:@core/bubblewrap:for building pure packages and running isolated apps",
		},
	},
})

function prepare()
	local archive = fetch_verified()
	UTILS.EXTRACT(archive, "source")

	UTILS.DOWNLOAD(release .. "/zoi.1", "zoi.1")
	UTILS.DOWNLOAD(release .. "/zoi-rs.3", "zoi-rs.3")
	UTILS.DOWNLOAD(release .. "/zoi-lua.5", "zoi-lua.5")

	UTILS.DOWNLOAD(release .. "/LICENSE", "LICENSE")
end

function package()
	local bin = "source/" .. binary_name()

	if ZOI.scope == "system" then
		zcp(bin, "${usrroot}/usr/bin/zoi")
	else
		zcp(bin, "${pkgstore}/bin/zoi")
	end

	cmd(bin .. " generate-completions bash > zoi.bash")
	cmd(bin .. " generate-completions zsh > _zoi")
	cmd(bin .. " generate-completions fish > zoi.fish")

	zshell("zoi.bash", "bash")
	zshell("_zoi", "zsh")
	zshell("zoi.fish", "fish")

	zman("zoi.1")
	zman("zoi-rs.3")
	zman("zoi-lua.5")

	zlicense("LICENSE")
end

function verify()
	local archive = archive_name()

	local sha = published_sha512(archive)
	if not sha then
		return false
	end

	return verifyHash(archive, "sha512-" .. sha) and verifySignature(archive, archive .. ".asc", public_key)
end

function test()
	local bin = LOCATION.STAGINGDIR .. "/data/pkgstore/bin/zoi"
	if ZOI.scope == "system" then
		bin = LOCATION.STAGINGDIR .. "/data/usrroot/usr/bin/zoi"
	end

	local _, _, code = cmd(bin .. " --version")
	return code == 0
end

function uninstall() end

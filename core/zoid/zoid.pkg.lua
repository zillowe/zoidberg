-- zoid, the ZoiOS privileged system daemon, installed from the project's own
-- pre-built release artifacts.
--
-- Like `zoi`, this fetches what the release pipeline already built and signed
-- (`scripts/linux-amd64.sh`, then `scripts/archive.sh`) rather than compiling
-- from source. `scripts/archive.sh` publishes `zoid-<os>-<arch>.tar.zst`
-- alongside the `zoi` archives, with the same `checksums.txt` and per-asset
-- detached signatures.

local version = "1.28.0"

-- Release tags are ZFVM "Branch-Status-Version", so the tag carries a prefix
-- that the bare SemVer in `metadata.version` does not. See `scripts/bump.sh`.
local tag = "Prod-Release-" .. version

local release = "https://gitlab.com/zillowe/zillwen/zusty/zoi/-/releases/"
	.. tag
	.. "/downloads"

-- The licence and the man page source are not inside the binary archive, so
-- they are read from the tag's tree.
local tree = "https://gitlab.com/zillowe/zillwen/zusty/zoi/-/raw/" .. tag

-- The key `scripts/archive.sh` signs with.
local public_key = "https://zillowe.pages.dev/keys/zillowe-main.asc"

-- Only Linux is listed. The daemon is a systemd unit that reconciles
-- `/etc/passwd`, the boot entries and system generations, none of which exist
-- on the platforms the release also builds `zoid` for.
local function archive_name()
	local os, arch = SYSTEM.OS, SYSTEM.ARCH

	if arch == "386" then
		error(
			"zoid has no pre-built 32-bit x86 artifact; the release pipeline "
				.. "builds amd64 and arm64 only"
		)
	end

	return "zoid-" .. os .. "-" .. arch .. ".tar.zst"
end

-- Reads this release's sha512 for `name` out of the published manifest, so the
-- digest is never hardcoded here and a new release needs no edit.
local function published_sha512(name)
	local manifest = io.open("checksums.txt", "r")
	if not manifest then
		return nil
	end

	for line in manifest:lines() do
		-- `sha512sum` output is "<hex>  ./<name>"; the name is matched in full
		-- after dropping the "./" that `find` prepends.
		local hash, entry = line:match("^(%x+)%s+%.?/(.+)$")
		if hash and entry == name then
			manifest:close()
			return hash
		end
	end

	manifest:close()
	return nil
end

local function fetch_verified()
	local archive = archive_name()

	UTILS.DOWNLOAD(release .. "/checksums.txt", "checksums.txt")

	local sha = published_sha512(archive)
	if not sha then
		error(
			"release " .. tag .. " publishes no sha512 for " .. archive
				.. "; either the artifact is missing or the manifest is "
				.. "malformed"
		)
	end

	-- The digest aborts the download on a mismatch, and the signature check
	-- below rejects an artifact that is intact but not from this project.
	UTILS.DOWNLOAD(release .. "/" .. archive, archive, "sha512-" .. sha)
	UTILS.DOWNLOAD(release .. "/" .. archive .. ".asc", archive .. ".asc")

	if not verifySignature(archive, archive .. ".asc", public_key) then
		error(
			"the signature on " .. archive .. " is not valid for the Zillowe "
				.. "release key; refusing to install it"
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
	platforms = { "linux-amd64", "linux-arm64" },
	tags = { "zillowe", "zoios", "daemon", "systemd" },
})

dependencies({
	build = {
		types = {
			["pre-compiled"] = {
				-- Rendered from the AsciiDoc in the tag's tree; the release
				-- archive carries only the bare binary.
				required = {
					"native:asciidoctor",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/zoi",
		},
	},
})

function prepare()
	local archive = fetch_verified()
	UTILS.EXTRACT(archive, "source")
end

function package()
	-- System scope only, so there is no pkgstore/user branch here: the daemon
	-- reconciles /etc/passwd and the boot entries and has no meaning outside a
	-- real root.
	zcp("source/zoid", "${usrroot}/usr/bin/zoid")

	-- The unit ships with this package rather than the binary archive, so the
	-- systemd unit and the daemon cannot drift apart across versions.
	zcp(
		"{pkgluadir}/zoid.service",
		"${usrroot}/usr/lib/systemd/system/zoid.service"
	)

	-- Rendered into man8, which `zman` infers from the `.8` extension, so
	-- `man 8 zoid` resolves.
	--
	-- This page is newer than 1.28.0, so at that tag the source is absent and
	-- the man page is skipped. Treating that as a warning rather than a failure
	-- is what lets this package track a release that predates its own page.
	if pcall(UTILS.DOWNLOAD, tree .. "/man/zoid.adoc", "zoid.adoc") then
		cmd("mkdir -p man && asciidoctor -b manpage -D man zoid.adoc")
		zman("man/zoid.8")
	else
		print("Warning: man/zoid.adoc is not in " .. tag .. "; skipping")
	end

	UTILS.DOWNLOAD(tree .. "/LICENSE", "LICENSE")
	zlicense("LICENSE")
end

function verify()
	-- Re-checked independently of prepare() so `zoi package verify` stands on
	-- its own.
	local archive = archive_name()

	local sha = published_sha512(archive)
	if not sha then
		return false
	end

	return verifyHash(archive, "sha512-" .. sha)
		and verifySignature(archive, archive .. ".asc", public_key)
end

function test()
	local bin = LOCATION.STAGINGDIR .. "/data/usrroot/usr/bin/zoid"

	local _, _, code = cmd(bin .. " --version")
	return code == 0
end

function uninstall() end

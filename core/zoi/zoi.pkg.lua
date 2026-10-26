-- Zoi, installed from the project's own pre-built release artifacts.
--
-- The release pipeline compiles and signs the binaries once per release tag
-- (`scripts/linux-amd64.sh` and friends build, `scripts/archive.sh` packages,
-- checksums and signs), so this package fetches those artifacts rather than
-- compiling anything. That keeps a `zoi` install down to a download, which
-- matters because the release binaries are the same ones `app/install.sh`
-- hands to users outside the registry.
--
-- Nothing here builds from source, so the package declares `pre-compiled` and
-- has no `build()` step.

local version = "1.28.0"

-- Release tags are ZFVM "Branch-Status-Version", so the tag carries a prefix
-- that the bare SemVer in `metadata.version` does not. See `scripts/bump.sh`.
local tag = "Prod-Release-" .. version

-- Artifacts (binaries, checksums, detached signatures) live on the release.
local release = "https://gitlab.com/zillowe/zillwen/zusty/zoi/-/releases/"
	.. tag
	.. "/downloads"

-- Files that are not shipped inside the binary archive - the licence and the
-- handwritten man page sources - are read from the tag's tree instead.
local tree = "https://gitlab.com/zillowe/zillwen/zusty/zoi/-/raw/" .. tag

-- The key `scripts/archive.sh` signs with. Same key `app/install.sh` trusts.
local public_key = "https://zillowe.pages.dev/keys/zillowe-main.asc"

local function platform()
	local os, arch = SYSTEM.OS, SYSTEM.ARCH

	-- `SYSTEM.ARCH` can report 32-bit x86, but the release pipeline has only
	-- ever produced amd64 and arm64. Saying so here beats letting the install
	-- fail later against a URL that does not exist.
	if arch == "386" then
		error(
			"zoi has no pre-built 32-bit x86 artifact; the release pipeline "
				.. "builds amd64 and arm64 only"
		)
	end

	return os, arch
end

-- The archive name the release publishes for the running platform.
--
-- Windows is zipped rather than tarred, which is why the extension is part of
-- the name rather than something appended later.
local function archive_name()
	local os, arch = platform()
	return "zoi-" .. os .. "-" .. arch
		.. (os == "windows" and ".zip" or ".tar.zst")
end

-- The single file inside the archive. `scripts/archive.sh` tars from a
-- directory holding just the binary, so there is no leading directory to strip.
local function binary_name()
	return SYSTEM.OS == "windows" and "zoi.exe" or "zoi"
end

-- Reads this release's sha512 for `name` out of the published manifest.
--
-- Verifying against `checksums.txt` rather than a hash written into this file
-- is what lets the package follow a new release without being edited: the hash
-- is whatever the release signed, and this file only has to know the tag.
local function published_sha512(name)
	local manifest = io.open("checksums.txt", "r")
	if not manifest then
		return nil
	end

	for line in manifest:lines() do
		-- `sha512sum` output is "<hex>  ./<name>". The name is matched in
		-- full after dropping the "./" that `find` adds, so the similarly
		-- named `.bsdiff` patch can never be mistaken for the archive.
		local hash, entry = line:match("^(%x+)%s+%.?/(.+)$")
		if hash and entry == name then
			manifest:close()
			return hash
		end
	end

	manifest:close()
	return nil
end

-- Fetches the release manifest, the archive and its signature, then checks both
-- the digest and the signature before anything is unpacked.
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

	-- Passing the digest makes UTILS.DOWNLOAD abort on a mismatch, so a
	-- truncated or substituted archive cannot reach the build directory.
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
	name = "zoi",
	repo = "core",
	version = version,
	revision = "1",
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
	-- The release publishes Linux builds only. Upstream also builds macOS and
	-- Windows, but the registry has no settled staging path for either, and
	-- `${usrroot}/usr/bin` is not a writable location on those systems.
	platforms = { "linux-amd64", "linux-arm64" },
	tags = { "zillowe", "package-manager", "cli" },
})

dependencies({
	build = {
		types = {
			["pre-compiled"] = {
				-- The man page is handwritten AsciiDoc in the tag's tree and is
				-- rendered here, because the release archive carries only the
				-- bare binary.
				required = {
					"native:asciidoctor",
				},
			},
		},
	},
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
end

function package()
	local bin = "source/" .. binary_name()

	if ZOI.scope == "system" then
		zcp(bin, "${usrroot}/usr/bin/zoi")
	else
		zcp(bin, "${pkgstore}/bin/zoi")
	end

	-- Completions come from the binary itself, so they always describe the
	-- installed version and cost nothing to produce.
	cmd(bin .. " generate-completions bash > zoi.bash")
	cmd(bin .. " generate-completions zsh > _zoi")
	cmd(bin .. " generate-completions fish > zoi.fish")

	zshell("zoi.bash", "bash")
	zshell("_zoi", "zsh")
	zshell("zoi.fish", "fish")

	-- The man page is AsciiDoc in the tag's tree, rendered here because the
	-- release archive carries only the bare binary.
	--
	-- A missing source is a warning rather than a failure: tags predating a
	-- given page must still install, and a tag that 404s on a man page is not a
	-- reason to refuse the binary.
	if pcall(UTILS.DOWNLOAD, tree .. "/man/zoi.adoc", "zoi.adoc") then
		cmd("mkdir -p man && asciidoctor -b manpage -D man zoi.adoc")
		zman("man/zoi.1")
	else
		print("Warning: man/zoi.adoc is not in " .. tag .. "; skipping")
	end

	UTILS.DOWNLOAD(tree .. "/LICENSE", "LICENSE")
	zlicense("LICENSE")
end

function verify()
	-- Re-checked independently of prepare(), so `zoi package verify` means
	-- something on its own rather than restating what the download already did.
	local archive = archive_name()

	local sha = published_sha512(archive)
	if not sha then
		return false
	end

	return verifyHash(archive, "sha512-" .. sha)
		and verifySignature(archive, archive .. ".asc", public_key)
end

function test()
	local bin = LOCATION.STAGINGDIR
		.. "/data/pkgstore/bin/zoi"
	if ZOI.scope == "system" then
		bin = LOCATION.STAGINGDIR .. "/data/usrroot/usr/bin/zoi"
	end

	local _, _, code = cmd(bin .. " --version")
	return code == 0
end

function uninstall() end

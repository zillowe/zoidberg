local version = ZOI.VERSION or "1.29.23"
local sha512 = "c09db02b839e6b271db3f3c2a9353988de5c21c35b42104c66c0ba0e0968524a75b06658c686a22b6fef18d7cdda7894a300606bff72abafdde42a5f19e66628"
local release = "https://gitlab.com/zillowe/zillwen/zusty/zoi/-/releases/Prod-Release-" .. version .. "/downloads"
-- Zillowe release signing key, as published at
-- https://zillowe.pages.dev/keys/zillowe-main.asc.
local signing_key = "B2DF6A70FAEBAF2F43D9D68B79590A44041642E9"

-- env.toml sits next to the recipe while building. An installed archive
-- carries only this file, and its build values are no longer needed then.
local env_ok, env = pcall(IMPORT, "env.toml")
if not env_ok and not tostring(env):find("No such file", 1, true) then
	error(env)
end
local build_env = env_ok and env or {}

metadata({
	name = "zoi",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
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
	-- Binaries of sub-packages other than the ones above.
	sub_bins = {
		zoid = { "zoid" },
	},
	types = { "source" },
	sub_packages = { "main", "zoid" },
	main_subs = { "main" },
	scope = "system",
	scopes = { "system" },
	zoios = true,
	platforms = { "linux-amd64" },
	tags = { "zillowe", "package-manager", "cli" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:asciidoctor",
					"pacman:base-devel",
					"pacman:clang",
					"pacman:curl",
					"pacman:just",
					"pacman:perl",
					"pacman:pkgconf",
					"pacman:rust",
				},
			},
		},
	},
	runtime = {
		sub_packages = {
			main = {
				required = {
					"zoi:@core/gcc:libgcc",
					"zoi:@core/gcc:libstdc++",
					"zoi:@core/git",
					"zoi:@core/glibc",
					-- liblzma (the xz2 crate) and libz (the built-in libgit2's
					-- zlib); libgit2, OpenSSL, SQLite and zstd are built
					-- into Zoi.
					"zoi:@core/xz",
					"zoi:@core/zlib",
				},
				optional = {
					"zoi:@core/bubblewrap:for building pure packages and running isolated apps",
				},
			},
			zoid = {
				required = {
					"zoi:@core/zoi:main",
				},
			},
		},
	},
})

-- zoid is the ZoiOS system daemon (`zoi system`, PackageKit), so it starts at
-- boot once installed. Hooks are shared by both sub-packages; the unit file
-- exists only when the zoid sub-package is installed.
hooks({
	post_install = {
		[[
		if [ -f /usr/lib/systemd/system/zoid.service ]; then
			systemctl enable zoid.service
		fi
		]],
	},
})

function prepare()
	local tarball = "zoi-" .. version .. ".tar.gz"
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors "$RELEASE/$TARBALL" -o "$TARBALL"
		curl -sSfL --retry 3 --retry-all-errors "$RELEASE/$TARBALL.asc" -o "$TARBALL.asc"
		echo "$SHA512  $TARBALL" | sha512sum -c -
	]],
		{ check = true, env = { RELEASE = release, TARBALL = tarball, SHA512 = sha512 } }
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad release signature on " .. tarball)
	end
	cmd([[tar -xf "$TARBALL"]], { check = true, env = { TARBALL = tarball } })
end

function build()
	local env = { VER = version }
	for name, value in pairs(build_env) do
		env[name] = value
	end
	cmd(
		[[
		cd "zoi-$VER"
		./configure --prefix=/usr --with-bin=all
		just build
		just man
		just completions
	]],
		{ check = true, env = env }
	)
end

function package(args)
	local src = "zoi-" .. version
	if args.sub == "zoid" then
		zcp(src .. "/target/release/zoid", "${usrroot}/usr/bin/zoid")
		zcp(src .. "/crates/daemon/zoid.service", "${usrroot}/usr/lib/systemd/system/zoid.service")
		-- Lets zoid own org.freedesktop.PackageKit on the system bus
		zcp(
			src .. "/crates/daemon/org.freedesktop.PackageKit.conf",
			"${usrroot}/usr/share/dbus-1/system.d/org.freedesktop.PackageKit.conf"
		)
		-- Restarts a running zoid after an update so the new daemon is loaded
		zcp("${pkgluadir}/hooks/zoid-restart.hook.yaml", "${pkgstore}/hooks/zoid-restart.hook.yaml")
		zman(src .. "/dist/man/zoid.8")
		zlicense(src .. "/LICENSE")
		return
	end

	local bin = src .. "/target/release/zoi"
	zcp(bin, "${usrroot}/usr/bin/zoi")

	local completions = src .. "/dist/completions/"
	zshell(completions .. "zoi.bash", "bash")
	zshell(completions .. "_zoi", "zsh")
	zshell(completions .. "zoi.fish", "fish")
	zshell(completions .. "zoi.elv", "elvish")

	zman(src .. "/dist/man/zoi.1")
	zman(src .. "/dist/man/zoi-rs.3")
	zman(src .. "/dist/man/zoi-lua.5")
	zlicense(src .. "/LICENSE")
end

function test()
	local _, _, code = cmd("/usr/bin/zoi --version")
	return code == 0
end

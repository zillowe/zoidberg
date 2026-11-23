local version = ZOI.VERSION or "2.6.2"
local sha512 = "fffad60003ba2e098d0a3e7df6bf194eaf38fd597b0711c02c9c52e5263f680a1effbc34e11d9b200691b60784e911fc08c21f0b478f964cc185e8a1c86f9bd8"
-- Release signing key (Tom Hromatka), listed in Arch Linux's validpgpkeys.
-- Paul Moore (7100AADFAE6E6E940D2E0AD655E45A5AE8CA7C8A) also signs releases,
-- but his key is only bound with SHA-1 self-signatures, which Zoi's verifier
-- rejects.
local signing_key = "47A68FCE37C7D7024FD65E11356CE62C2B524099"

metadata({
	name = "libseccomp",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Enhanced seccomp library",
	website = "https://github.com/seccomp/libseccomp",
	license = "LGPL-2.1-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Paul Moore",
		website = "https://github.com/seccomp/libseccomp",
	},
	bins = { "scmp_sys_resolver" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	sub_packages = { "main", "python" },
	main_subs = { "main" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:cython",
					"pacman:gcc",
					"pacman:gperf",
					"pacman:make",
					"pacman:python",
					"pacman:python-build",
					"pacman:python-installer",
					"pacman:python-setuptools",
					"pacman:python-wheel",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
		sub_packages = {
			main = {
				required = {
					"zoi:@core/glibc",
				},
			},
			-- Python bindings, split like Arch Linux's python-libseccomp. The
			-- extension links libseccomp statically.
			python = {
				required = {
					"zoi:@core/glibc",
					"zoi:@core/python",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libseccomp-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/seccomp/libseccomp/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libseccomp-$VER.tar.gz"
		fetch "libseccomp-$VER.tar.gz.asc"
		echo "$SHA512  libseccomp-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libseccomp-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "libseccomp-$VER"
		# The static library is built because the Python extension links
		# ../.libs/libseccomp.a; it is not shipped.
		./configure --prefix=/usr
		make -j"$(nproc)"

		cd src/python
		VERSION_RELEASE="$VER" CPPFLAGS="${CPPFLAGS:-} -I$PWD/../../include" \
			python -m build --wheel --no-isolation
	]],
		opts
	)
end

function package(args)
	local sub = (args and args.sub) or "main"
	local src = "libseccomp-" .. version

	if sub == "main" or sub == "" then
		cmd(
			[[
			cd "libseccomp-$VER"
			make DESTDIR="$ROOT" install
			rm -f "$ROOT"/usr/lib/libseccomp.a
		]],
			opts
		)
		zdoc(src .. "/CHANGELOG")
		zdoc(src .. "/README.md")
		zdoc(src .. "/SECURITY.md")
	elseif sub == "python" then
		cmd(
			[[
			cd "libseccomp-$VER/src/python"
			VERSION_RELEASE="$VER" python -m installer --destdir="$ROOT" dist/*.whl
		]],
			opts
		)
	end

	zlicense(src .. "/LICENSE")
end

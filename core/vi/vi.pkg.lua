local version = ZOI.VERSION or "070224"
local sha512 = "3f79b22279f874732d6cd3a715c65d7ea368c02712646b3dc25413726bf6a020addc05808bceb29a8fc45a3b8fb62210f68753ab422152a751decbec44ea46dd"
-- Upstream (ex-vi.sourceforge.net) stopped releasing in 2007. This is Arch
-- Linux's copy of the last release, as Arch's PKGBUILD uses it. Its 2015
-- signature (by Evangelos Foutras, 86CFFCA918CF3AF47147588051E8B148A9999C34)
-- dates from when his key had only SHA-1 self-signatures, which Zoi's
-- signature policy (Sequoia's standard policy) rejects. The tarball is
-- pinned by the hash instead, which matches Arch's checksum; the signature
-- was checked with GnuPG when the hash was pinned.

metadata({
	name = "vi",
	repo = "core",
	version = version,
	-- As in Arch Linux, whose earlier vi releases had larger version numbers.
	epoch = 1,
	revision = "1",
	debug = { sub_package = true },
	description = "The original ex/vi text editor",
	website = "https://ex-vi.sourceforge.net/",
	license = "BSD-4-Clause-UC AND Caldera-no-preamble",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Gunnar Ritter",
		website = "https://ex-vi.sourceforge.net/",
	},
	bins = { "vi", "ex", "view", "edit", "vedit" },
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
					"pacman:base-devel",
					"pacman:gcc",
					"pacman:make",
					"pacman:ncurses",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

-- The make variables Arch Linux builds and installs with.
local make_vars = [[PREFIX=/usr LIBEXECDIR=/usr/lib/ex PRESERVEDIR=/var/lib/ex]]

function prepare()
	cmd(
		[[
		base="https://sources.archlinux.org/other/vi"
		curl -sSfL --retry 3 --retry-all-errors "$base/ex-$VER.tar.xz" -o "ex-$VER.tar.xz"
		echo "$SHA512  ex-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	-- Arch Linux's patches: a tube-size overflow, arrow and navigation keys,
	-- format-string safety, line numbers (FS#70770) and the preserve
	-- directory (FS#20653).
	cmd(
		[[
		tar -xf "ex-$VER.tar.xz"
		cd "ex-$VER"
		for p in fix-tubesize-short-overflow navkeys format-security \
			linenum preserve-dir; do
			patch -Np1 -i "$PKGLUADIR/patches/$p.patch"
		done
		# The two licenses LICENSE holds, split as Arch Linux does.
		sed -n '1,36p' LICENSE > BSD-4-Clause-UC.txt
		sed -n '39,69p' LICENSE > Caldera-no-preamble.txt
	]],
		opts
	)
end

function build()
	-- Options follow Arch Linux's PKGBUILD.
	cmd(
		[[
		cd "ex-$VER"
		make ]] .. make_vars .. [[ TERMLIB=ncurses \
			FEATURES="-DCHDIR -DFASTTAG -DUCVISUAL -DMB -DBIT8"
	]],
		opts
	)
end

function package()
	-- STRIP is emptied so the debug sub-package keeps the symbols; Zoi strips
	-- the installed binaries itself.
	cmd(
		[[
		cd "ex-$VER"
		make ]] .. make_vars .. [[ INSTALL=/usr/bin/install STRIP= \
			DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "ex-" .. version
	zlicense(src .. "/BSD-4-Clause-UC.txt")
	zlicense(src .. "/Caldera-no-preamble.txt")
end

function test()
	-- Edits a file in ex mode, as POSIX scripts drive it.
	cmd(
		[[
		printf 'one\n' > ex-test.txt
		printf 'a\ntwo\n.\nwq\n' | "$ROOT/usr/bin/ex" -s ex-test.txt
		test "$(cat ex-test.txt)" = "$(printf 'one\ntwo')"
		rm ex-test.txt
	]],
		opts
	)
	return true
end

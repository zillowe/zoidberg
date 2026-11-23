local version = ZOI.VERSION or "1.0"
local sha512 = "fa657faf5685dae7121a9b0293d3308a3910a72b90943a7a493b88cf88e95f29c5758e1573320169fe9beac6f101ef76f4165a279a7f3294155d7a773e2fa09f"
-- Release signing key (Bruno Haible), from the GNU keyring.
local signing_key = "E0FFBD975397F77A32AB76ECB6301D9E1BBEAC08"

metadata({
	name = "gettext",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "GNU internationalization and localization system",
	website = "https://www.gnu.org/software/gettext/",
	license = "GPL-3.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = {
		"autopoint",
		"envsubst",
		"gettext",
		"gettext.sh",
		"gettextize",
		"msgattrib",
		"msgcat",
		"msgcmp",
		"msgcomm",
		"msgconv",
		"msgen",
		"msgexec",
		"msgfilter",
		"msgfmt",
		"msggrep",
		"msginit",
		"msgmerge",
		"msgunfmt",
		"msguniq",
		"ngettext",
		"recode-sr-latin",
		"xgettext",
	},
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
					"pacman:acl",
					"pacman:attr",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:json-c",
					"pacman:libunistring",
					"pacman:libxml2",
					"pacman:make",
					"pacman:ncurses",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/acl",
			"zoi:@core/attr",
			"zoi:@core/bash",
			"zoi:@core/curl",
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libgomp",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
			"zoi:@core/gnulib-l10n",
			"zoi:@core/json-c",
			"zoi:@core/libunistring",
			"zoi:@core/libxml2",
			"zoi:@core/ncurses",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "gettext-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/gettext" \
				"https://ftp.gnu.org/gnu/gettext" \
				"https://mirrors.kernel.org/gnu/gettext"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "gettext-$VER.tar.xz"
		fetch "gettext-$VER.tar.xz.sig"
		echo "$SHA512  gettext-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "gettext-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "gettext-$VER"

		touch -c aclocal.m4 configure Makefile.in

		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--enable-nls \
			--with-xz \
			--without-included-gettext

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "gettext-$VER" DESTDIR="$ROOT" install

		# Licenses of the tree-sitter parsers built into xgettext, gathered
		# under distinct names.
		rm -rf licenses-tree-sitter
		mkdir licenses-tree-sitter
		for d in "gettext-$VER"/gettext-tools/tree-sitter-*/; do
			name="$(basename "$d")"
			install -m644 "$d/LICENSE" "licenses-tree-sitter/LICENSE.$name"
		done
	]],
		opts
	)

	zlicense("gettext-" .. version .. "/COPYING")
	zlicense("gettext-" .. version .. "/gettext-runtime/intl/COPYING.LIB")
	zlicense("licenses-tree-sitter")
end

function test()
	cmd([[
		/usr/bin/gettext --version || gettext --version || true
	]])
end

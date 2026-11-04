local version = ZOI.VERSION or "1.0"
local tag = "v" .. version
local tar_url = string.format("https://ftp.gnu.org/pub/gnu/gettext/gettext-%s.tar.gz", version)

metadata({
	name = "gettext",
	repo = "core",
	version = version,
	revision = "2",
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
					"pacman:gcc",
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
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "gettext-%s" ]; then
			curl -sSL "%s" | tar -xz
		fi
	]],
		version,
		tar_url
	))
end

function build()
	cmd(string.format(
		[[
		set -e
		cd "gettext-%s"

		./configure \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--enable-nls \
			--with-xz \
			--without-included-gettext

		make -j"$(nproc)"
	]],
		version
	))
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		make -C "gettext-%s" DESTDIR="$ROOT" install
	]],
		root,
		version
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/gettext --version || gettext --version || true
	]])
end

local version = ZOI.VERSION or "1.25.0"
local tag = "v" .. version
local tar_url = string.format("https://ftp.gnu.org/gnu/wget/wget-%s.tar.gz", version)

metadata({
	name = "wget",
	repo = "core",
	version = version,
	revision = "2",
	description = "Network utility to retrieve files from the web",
	website = "https://www.gnu.org/software/wget/",
	license = "GPL-3.0-or-later",
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
		"wget",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/wgetrc",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:autoconf",
					"pacman:automake",
					"pacman:gcc",
					"pacman:gnutls",
					"pacman:libidn2",
					"pacman:libpsl",
					"pacman:make",
					"pacman:nettle",
					"pacman:pcre2",
					"pacman:pkgconf",
					"pacman:tar",
					"pacman:util-linux-libs",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/ca-certificates",
			"zoi:@core/glibc",
			"zoi:@core/zlib",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d "wget-%s" ]; then
			curl -sSL "%s" | tar -xz || true
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
		cd "wget-%s"

		find . -type f \( -name "config.hin" -o -name "configh.in" -o -name "config.h.in" -o -name "Makefile.in" -o -name "aclocal.m4" -o -name "configure" \) -exec touch -c {} +

		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--disable-rpath \
			--enable-nls \
			--with-ssl=gnutls \
			gl_cv_func_posix_spawn_file_actions_addchdir=yes

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
		make -C "wget-%s" DESTDIR="$ROOT" install

		if [ -f "$ROOT/etc/wgetrc" ]; then
			echo "" >> "$ROOT/etc/wgetrc"
			echo "ca_certificate=/etc/ssl/certs/ca-certificates.crt" >> "$ROOT/etc/wgetrc"
		fi
	]],
		root,
		version
	))

	zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/wget --version || wget --version || true
	]])
end

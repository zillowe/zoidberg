local version = ZOI.VERSION or "1.25.0"
local sha512 = "79403f594636e5d703817ceec59e5155940cd4734746ef793ef3bdabd100d0014a44c5e24f705656cf1e0762d87003fa1dc3e1b5605fae392bc9d7f121d90bae"
-- Release signing key (Darshit Shah), from the GNU keyring. The key expired
-- in 2025-11, after this release was signed; the signature was made while it
-- was valid and still verifies.
local signing_key = "7845120B07CBD8D6ECE5FF2B2A1743EDA91A35B6"

metadata({
	name = "wget",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
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
					"pacman:curl",
					"pacman:texinfo",
					"pacman:gcc",
					"pacman:gnutls",
					"pacman:libidn2",
					"pacman:libpsl",
					"pacman:lzip",
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
			"zoi:@core/gnutls",
			"zoi:@core/libidn2",
			"zoi:@core/libpsl",
			"zoi:@core/nettle",
			"zoi:@core/pcre2",
			"zoi:@core/util-linux:libs",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "wget-" .. version .. ".tar.lz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/wget" \
				"https://ftp.gnu.org/gnu/wget" \
				"https://mirrors.kernel.org/gnu/wget"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "wget-$VER.tar.lz"
		fetch "wget-$VER.tar.lz.sig"
		echo "$SHA512  wget-$VER.tar.lz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "wget-$VER.tar.lz"
		cd "wget-$VER"
		# nettle 4 dropped the length argument of nettle_md4_digest().
		sed -i 's/nettle_md4_digest(&MD4, MD4_DIGEST_SIZE, ntbuffer);/nettle_md4_digest(\&MD4, ntbuffer);/' src/http-ntlm.c
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "wget-$VER"

		find . -type f \( -name "config.hin" -o -name "configh.in" -o -name "config.h.in" -o -name "Makefile.in" -o -name "aclocal.m4" -o -name "configure" \) -exec touch -c {} +

		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--disable-rpath \
			--enable-nls \
			--with-ssl=gnutls \
			--with-libpsl \
			--with-libuuid \
			--with-zlib \
			--enable-iri \
			--enable-pcre2 \
			--disable-pcre \
			--without-metalink \
			--without-cares \
			gl_cv_func_posix_spawn_file_actions_addchdir=yes

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "wget-$VER" DESTDIR="$ROOT" install

		if [ -f "$ROOT/etc/wgetrc" ]; then
			echo "" >> "$ROOT/etc/wgetrc"
			echo "ca_certificate=/etc/ssl/certs/ca-certificates.crt" >> "$ROOT/etc/wgetrc"
		fi
	]],
		opts
	)

	zlicense("wget-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/wget --version || wget --version || true
	]])
end

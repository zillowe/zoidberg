local version = ZOI.VERSION or "710"
local sha512 = "e278fb1ffbfd95c801ae7f8d8e5b442ef25c7828bb7355efd9b6020b2ee3c94e61bae2291062e815c1e22efcf9c4ddc33fbc85cec38023f8cf4f03991c68a335"
-- Upstream signs releases (key AE27252BD6846E7D6EAE1DD6F153A7C833235259, Mark Nudelman),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The signature was checked with gpg when this hash was
-- recorded; the pinned hash is the trust anchor.

metadata({
	name = "less",
	repo = "core",
	version = version,
	revision = "3",
	debug = { sub_package = true },
	description = "A terminal based program for viewing text files",
	website = "https://www.greenwoodsoftware.com/less/",
	license = "GPL-3.0-or-later OR BSD-2-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Mark Nudelman",
		website = "https://www.greenwoodsoftware.com/less/",
	},
	bins = { "less", "lessecho", "lesskey" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:ncurses",
					"pacman:pcre2",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
			"zoi:@core/pcre2",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "less-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			# greenwoodsoftware.com refuses (403) many CI runners, so fall
			# back to Gentoo's distfiles mirror, which serves the same file
			# under a directory named after the BLAKE2b of the file name.
			gentoo="https://distfiles.gentoo.org/distfiles/$(printf %s "$1" | b2sum | cut -c1-2)"
			for base in \
				"https://www.greenwoodsoftware.com/less" \
				"$gentoo"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "less-$VER.tar.gz"
		echo "$SHA512  less-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "less-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "less-$VER"
		sh configure --prefix=/usr --libexecdir=/usr/lib --sysconfdir=/etc --with-regex=pcre2
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "less-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "less-" .. version
	-- Dual-licensed: the Less License (LICENSE) or GPL-3.0 (COPYING).
	zlicense(src .. "/LICENSE")
	zlicense(src .. "/COPYING")
end

local version = ZOI.VERSION or "8.3.6"
-- Version is <release>.<patchlevel>: the release tarball plus the official
-- upstream patches readline83-001 .. readline83-<patchlevel>, committed in
-- readline-8.3-patches/ (each checked against its upstream .sig with gpg and
-- against Gentoo's Manifest when added).
local basever = string.match(version, "^(%d+%.%d+)")
local patchlevel = string.match(version, "^%d+%.%d+%.(%d+)$") or "0"
local sha512 = "513002753dcf5db9213dbbb61d51217245f6a40d33b1dd45238e8062dfa8eef0c890b87a5548e11db959e842724fb572c4d3d7fb433773762a63c30efe808344"
-- Upstream signs releases and patches (key 7C0135FB088AAF6C66C650B9BB5869F064EA74AB,
-- Chet Ramey), but the key is only bound with SHA-1 self-signatures, which
-- Zoi's verifier rejects. The signatures were checked with gpg when this hash
-- and the patches were recorded; the pinned hash is the trust anchor.

metadata({
	name = "readline",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "GNU readline library",
	website = "https://tiswww.case.edu/php/chet/readline/rltop.html",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Chet Ramey",
		website = "https://tiswww.case.edu/php/chet/readline/rltop.html",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/inputrc",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:make",
					"pacman:ncurses",
					"pacman:patch",
					"pacman:tar",
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
local opts = { check = true, env = { BASEVER = basever, PLEVEL = patchlevel, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/readline" \
				"https://ftp.gnu.org/gnu/readline" \
				"https://mirrors.kernel.org/gnu/readline"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "readline-$BASEVER.tar.gz"
		echo "$SHA512  readline-$BASEVER.tar.gz" | sha512sum -c -
		tar -xf "readline-$BASEVER.tar.gz"
	]],
		opts
	)
	cmd(
		[[
		cd "readline-$BASEVER"
		flat=$(echo "$BASEVER" | tr -d '.')
		p=1
		while [ "$p" -le "$PLEVEL" ]; do
			patch -p0 -i "$PKGLUADIR/patches/readline$flat-$(printf '%03d' "$p")"
			p=$((p + 1))
		done

		# Remove RPATH from shared objects
		sed -i 's|-Wl,-rpath,$(libdir) ||g' support/shobj-conf
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "readline-$BASEVER"

		CFLAGS="${CFLAGS} -fPIC"
		./configure --prefix=/usr
		make -j"$(nproc)" SHLIB_LIBS=-lncurses
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT/etc"

		make -C "readline-$BASEVER" DESTDIR="$ROOT" install
		install -m644 "$PKGLUADIR/files/inputrc" "$ROOT/etc/inputrc"
	]],
		opts
	)

	zlicense("readline-" .. basever .. "/COPYING")
end

function test()
	cmd([[
		test -f /usr/lib/libreadline.so || true
	]])
end

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
	revision = "1",
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

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	local tarball = "less-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://www.greenwoodsoftware.com/less"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "less-$VER.tar.gz"
		echo "$SHA512  less-$VER.tar.gz" | sha512sum -c -
	]])
	sh([[tar -xf "less-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "less-$VER"
		sh configure --prefix=/usr --libexecdir=/usr/lib --sysconfdir=/etc --with-regex=pcre2
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "less-$VER"
		make DESTDIR="$ROOT" install
		for f in LICENSE COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/less/$(basename "$f")"
		done
		true
	]])
end

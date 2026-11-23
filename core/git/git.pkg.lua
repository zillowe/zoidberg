local version = ZOI.VERSION or "2.56.1"
local sha512 = "61b657e0b852f4e0a6a84af77d1e296b60bd6308a75014fc49fc83fda17052143d05bb4bfb521b3aceca7aa32a2f3a98cee6b4852c8dcc7ae481645480671a4c"
-- Upstream signs releases (key 96E07AF25771955980DAD10020D04E5A713660A7, Junio C Hamano),
-- but the key is only bound with SHA-1 self-signatures, which Zoi's
-- verifier rejects. The hash was taken from Gentoo's Manifest for the same
-- kernel.org tarball; the pinned hash is the trust anchor.

metadata({
	name = "git",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "The fast distributed version control system",
	website = "https://git-scm.com/",
	license = "GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Git developers",
		website = "https://git-scm.com/",
	},
	bins = {
		"git",
		"git-cvsserver",
		"git-receive-pack",
		"git-shell",
		"git-upload-archive",
		"git-upload-pack",
		"scalar",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	quiet = { "build" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:asciidoc",
					"pacman:curl",
					"pacman:expat",
					"pacman:gcc",
					"pacman:make",
					"pacman:openssl",
					"pacman:pcre2",
					"pacman:perl",
					"pacman:python",
					"pacman:rust",
					"pacman:xmlto",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/curl",
			"zoi:@core/expat",
			"zoi:@core/glibc",
			"zoi:@core/grep",
			"zoi:@core/openssl",
			"zoi:@core/pcre2",
			"zoi:@core/perl",
			"zoi:@core/perl-error",
			"zoi:@core/perl-mailtools",
			"zoi:@core/shadow",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

-- Shared make invocation, prepended to the build and package steps.
local git_make = [[
# Perl distributions keep pod2man and friends in the core_perl script dir
export PATH="$PATH:/usr/bin/core_perl:/usr/bin/vendor_perl"
_make() {
	make \
		prefix=/usr \
		gitexecdir=/usr/lib/git-core \
		perllibdir="$(/usr/bin/perl -MConfig -wle 'print $Config{installvendorlib}')" \
		CFLAGS="${CFLAGS:--O2 -pipe}" \
		LDFLAGS="${LDFLAGS:-}" \
		INSTALL_SYMLINKS=1 \
		MAN_BOLD_LITERAL=1 \
		NO_PERL_CPAN_FALLBACKS=1 \
		USE_LIBPCRE2=1 \
		WITH_RUST=1 \
		"$@"
}
]]

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.kernel.org/pub/software/scm/git" \
				"https://mirrors.kernel.org/pub/software/scm/git"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "git-$VER.tar.xz"
		echo "$SHA512  git-$VER.tar.xz" | sha512sum -c -
		tar -xf "git-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	-- The libsecret credential helper is not built; Parlex ships no libsecret.
	cmd(
		git_make
			.. [[
		cd "git-$VER"
		_make -j"$(nproc)" all man
		_make -j"$(nproc)" -C contrib/subtree all man
		_make -C contrib/diff-highlight
	]],
		opts
	)
end

function package()
	cmd(
		git_make
			.. [[
		mkdir -p "$ROOT"
		cd "git-$VER"

		_make DESTDIR="$ROOT" install install-man

		mkdir -p "$ROOT/usr/share/bash-completion/completions/"
		install -m0644 contrib/completion/git-completion.bash "$ROOT/usr/share/bash-completion/completions/git"
		mkdir -p "$ROOT/usr/share/git/"
		install -m0644 contrib/completion/git-prompt.sh "$ROOT/usr/share/git/git-prompt.sh"

		_make -C contrib/subtree DESTDIR="$ROOT" install install-man

		find contrib/ -name '.gitignore' -delete
		cp -a contrib/* "$ROOT/usr/share/git/"

		install -Dm644 "$PKGLUADIR/files/git-daemon@.service" "$ROOT/usr/lib/systemd/system/git-daemon@.service"
		install -Dm644 "$PKGLUADIR/files/git-daemon.socket" "$ROOT/usr/lib/systemd/system/git-daemon.socket"
		install -Dm644 "$PKGLUADIR/files/git-sysusers.conf" "$ROOT/usr/lib/sysusers.d/git.conf"
	]],
		opts
	)

	-- Register git-shell as a valid login shell
	zcp("${pkgluadir}/hooks/git-shell-add.hook.yaml", "${pkgstore}/hooks/git-shell-add.hook.yaml")
	zcp("${pkgluadir}/hooks/git-shell-remove.hook.yaml", "${pkgstore}/hooks/git-shell-remove.hook.yaml")

	zlicense("git-" .. version .. "/COPYING")
	zlicense("git-" .. version .. "/LGPL-2.1")
end

function test()
	cmd([[
		/usr/bin/git --version || git --version
	]])
end

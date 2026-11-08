local version = ZOI.VERSION or "2.56.0"

metadata({
	name = "git",
	repo = "core",
	version = version,
	revision = "1",
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
					"pacman:git",
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
			"zoi:@core/shadow",
			"zoi:@core/zlib",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "ROOT='" .. root .. "'\n"
		.. [[
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
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d git ]; then
			git clone --depth 1 --branch "v$VER" https://github.com/git/git.git git
		fi
	]])
end

function build()
	-- The libsecret credential helper is not built; Parlex ships no libsecret.
	sh([[
		cd git
		_make -j"$(nproc)" all man
		_make -j"$(nproc)" -C contrib/subtree all man
		_make -C contrib/diff-highlight
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd git

		_make DESTDIR="$ROOT" install install-man

		mkdir -p "$ROOT/usr/share/bash-completion/completions/"
		install -m0644 contrib/completion/git-completion.bash "$ROOT/usr/share/bash-completion/completions/git"
		mkdir -p "$ROOT/usr/share/git/"
		install -m0644 contrib/completion/git-prompt.sh "$ROOT/usr/share/git/git-prompt.sh"

		_make -C contrib/subtree DESTDIR="$ROOT" install install-man

		find contrib/ -name '.gitignore' -delete
		cp -a contrib/* "$ROOT/usr/share/git/"

		install -Dm644 "$PKGLUADIR/git-daemon@.service" "$ROOT/usr/lib/systemd/system/git-daemon@.service"
		install -Dm644 "$PKGLUADIR/git-daemon.socket" "$ROOT/usr/lib/systemd/system/git-daemon.socket"
		install -Dm644 "$PKGLUADIR/git-sysusers.conf" "$ROOT/usr/lib/sysusers.d/git.conf"
	]])

	-- Register git-shell as a valid login shell
	zcp("${pkgluadir}/hooks/git-shell-add.hook.yaml", "${pkgstore}/hooks/git-shell-add.hook.yaml")
	zcp("${pkgluadir}/hooks/git-shell-remove.hook.yaml", "${pkgstore}/hooks/git-shell-remove.hook.yaml")
end

function test()
	cmd([[
		/usr/bin/git --version || git --version
	]])
end

local repo_owner = "eza-community"
local repo_name = "eza"
local version = SYSTEM.VERSION or "0.23.3"
local git_url = "https://github.com/" .. repo_owner .. "/" .. repo_name .. ".git"

package({
	name = repo_name,
	repo = "community",
	version = version,
	description = "eza is a modern alternative for the venerable file-listing command-line program ls that ships with Unix and Linux operating systems, giving it more features and better defaults",
	website = "https://eza.rocks/",
	git = git_url,
	maintainer = {
		name = "Zillowe Community",
		website = "https://gitlab.com/Zillowe/Zillwen/Zusty/Zoidberg",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Christina Sørensen",
		email = "christina@cafkafk.com",
	},
	license = "EUPL-1.2",
	bins = { "eza" },
	conflicts = { "eza" },
})

install({
	{
		name = "Build from source",
		type = "source",
		url = PKG.git,
		platforms = { "all" },
		build_commands = {
			"cargo build --release",
		},
		bin_path = "target/release/eza",
	},
})

dependencies({
	build = {
		required = { "native:cargo" },
	},
})

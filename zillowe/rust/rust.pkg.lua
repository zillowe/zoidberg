local version = ZOI.VERSION or "1.0.0"

metadata({
	name = "rust",
	repo = "zillowe",
	type = "app",
	version = version,
	revision = "3",
	description = "A Rust project template with the Zillowe conventions: rustfmt, .editorconfig, workspace lints, Justfile and CI.",
	website = "https://zillowe.qzz.io",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	types = { "source" },
	license = "Apache-2.0",
	platforms = { "linux-amd64", "macos" },
})

dependencies({
	runtime = {},
})

function package()
	-- Workspace root.
	zcp("${pkgluadir}/template/Cargo.toml", "${createpkgdir}/Cargo.toml")
	zcp("${pkgluadir}/template/rustfmt.toml", "${createpkgdir}/rustfmt.toml")
	zcp("${pkgluadir}/template/.editorconfig", "${createpkgdir}/.editorconfig")
	zcp("${pkgluadir}/template/Justfile", "${createpkgdir}/Justfile")
	zcp("${pkgluadir}/template/.gitignore", "${createpkgdir}/.gitignore")
	zcp("${pkgluadir}/template/.gitlab-ci.yml", "${createpkgdir}/.gitlab-ci.yml")
	zcp("${pkgluadir}/template/renovate.json", "${createpkgdir}/renovate.json")
	zcp("${pkgluadir}/template/README.md", "${createpkgdir}/README.md")
	zcp("${pkgluadir}/template/LICENSE", "${createpkgdir}/LICENSE")
	zcp("${pkgluadir}/template/LICENSE-MIT", "${createpkgdir}/LICENSE-MIT")

	-- The crate itself.
	zcp("${pkgluadir}/template/crates/app", "${createpkgdir}/crates/app")
end

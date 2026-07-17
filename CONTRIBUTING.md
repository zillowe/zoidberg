# Contributing

Thank you for your interest in contributing to the Zoidberg package registry! This guide covers how to add new packages, report vulnerabilities, and understand our licensing.

## Adding a Package

All package submissions must follow the official [Zoidberg Packaging Guidelines](https://zillowe.qzz.io/docs/zds/zoi/zoidberg-guidelines).

### 1. Directory Structure

Each package lives in its own directory under the appropriate repo tier:

```
zoidberg/
├── core/
│   └── <package-name>/
│       ├── <package-name>.pkg.lua
│       └── nvchecker.toml      (optional, for auto-updates)
├── main/
│   └── ...
├── extra/
├── community/
├── zillowe/
└── ...
```

Choose the repo based on the package's maturity:

- `core/`: Essential packages and libraries; very common and well-maintained.
- `main/`: Important packages that don't fit in `core` but are essential for most users.
- `extra/`: New or niche packages; less common and may be less actively maintained.
- `community/`: User-submitted packages. New entries start here and may graduate to higher tiers.
- `zillowe/`: Official packages from Zillowe Foundation.

### 2. Package Definition (`.pkg.lua`)

Create a `.pkg.lua` file that describes your package. Use [`@zillowe/hello`](https://github.com/zillowe/hello) as a reference example.

Key requirements:

- `metadata{...}` with the package name, repo tier, version, description, maintainer, and license.
- Lifecycle functions (`prepare`, `build`, `package`, `verify`) to fetch, compile, stage, and verify.
- Dependencies declared via `dependencies{...}` where applicable.

Learn more in the [Creating Packages](https://zillowe.qzz.io/docs/zds/zoi/creating-packages) guide.

### 3. Auto-Updates with `nvchecker.toml` (Recommended)

To enable automatic version checks, place an `nvchecker.toml` file next to your `.pkg.lua`. This lets `nvchecker` detect new upstream releases and report them.

**GitHub source:**

```toml
[<package-name>]
source = "github"
github = "owner/repo"
use_max_tag = true
```

**GitLab source:**

```toml
[<package-name>]
source = "gitlab"
gitlab = "namespace/project/path"
use_max_tag = true
```

See existing examples:

- [`@zillowe/zoko`](./zillowe/zoko/nvchecker.toml) (GitLab)
- [`@main/ripgrep`](./main/ripgrep/nvchecker.toml) (GitHub)

### 4. Submitting

Create a Merge Request on [GitLab](https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/merge_requests). Issues for package requests can also be opened on any of the [Zoidberg mirrors](./README.md#mirrors).

Make sure your MR:

- Follows the [Zoidberg Packaging Guidelines](/docs/zds/zoi/zoidberg-guidelines).
- Includes a complete `.pkg.lua` with all required lifecycle functions.
- Optionally includes an `nvchecker.toml` for auto-update support.
- Has been tested locally with `zoi package build --type <type> <package>.pkg.lua`.

## Reporting Security Vulnerabilities

If you discover a security vulnerability in a Zoidberg package, please report it by following the [Security Advisories guide](/docs/zds/zoi/guides/security-advisories).

In short:

1. Create a `.sec.yaml` advisory file in the package's directory.
2. Use a temporary ID format: `ZSA-YYYY-TEMP.sec.yaml`.
3. Submit a Merge Request on [GitLab](https://gitlab.com/zillowe/zillwen/zusty/zoidberg).

## License

All package definitions (`.pkg.lua`, `nvchecker.toml`, and related metadata files) in this registry are licensed under Apache 2.0 unless explicitly stated otherwise in a `LICENSE` file in the package directory.

The upstream software distributed by these packages is governed by its own respective licenses.

<div align="center">
    <img width="320" hspace="10" alt="Zoidberg Banner" src="https://gitlab.com/zillowe/zillwen/zusty/zoi/-/raw/main/app/images/zoidberg-banner.svg"/>
    <p><strong>The official Zoi packages repository</strong></p>
</div>
<hr/>
<br/>

<div align="center">
  <a href="https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/issues/new?issuable_template=New%20Package%20Request"><strong>New Package Request</strong></a> •
  <a href="https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/issues/new?issuable_template=Package%20Update%20or%20Removal"><strong>Package Update or Removal</strong></a>
  <br/>
  <a href="https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/issues/new?issuable_template=Security%20Vulnerability%20Report"><strong>Security Vulnerability Report</strong></a> •
  <a href="https://zillowe.qzz.io/docs/zds/zoi/zoidberg-guidelines"><strong>Zoidberg Guidelines</strong></a>
  <br/>
</div>

<br/>
<hr/>
<br/>

## Installing a package

To use Zoidberg packages with Zoi you'll need [Zoi](https://github.com/zillowe/zoi) installed first.

Zoidberg is the default package registry that comes with Zoi, could be different if you didn't use Zoi's [official binaries](https://github.com/zillowe/zoi/blob/main/SECURITY.md) or compiled your own with a different registry, [learn more](https://github.com/zillowe/zoi/blob/main/PACKAGING.md).

If you installed Zoi from an unofficial source you'll need to add PGP keys of the maintainers of Zoidberg to be able to sync packages safely, if you installed Zoi from an official source you won't need to do that because it's backed into Zoi:

```sh
zoi pgp add https://zillowe.pages.dev/keys/zillowez.asc
```

To check which registry you're using run this command:

```sh
zoi sync list
```

### Mirrors

If you want to use any of Zoidberg's mirrors run this:

```sh
zoi sync set {mirror}
# default (the packagers default one), gitlab, github, codeberg (Zoidberg mirrors)
```

Official mirrors:

- Primary: [GitLab](https://gitlab.com/zillowe/zillwen/zusty/zoidberg)
- Mirrors: [GitHub](https://github.com/zillowe/zoidberg), [Codeberg](https://codeberg.org/zillowe/zoidberg)

Once you've confirmed its Zoidberg run this command to sync the registry locally:

```sh
zoi sync
```

Now you can install any package from Zoidberg, for example `@zillowe/hello` package:

```sh
zoi install @zillowe/hello
```

Now run the `hello` app from your terminal and it should print: `Hello, World!`.

Learn how to use Zoi by visiting the [docs](https://zillowe.qzz.io/docs/zds/zoi).

## Repos

Zoidberg consists of different [repos](https://zillowe.qzz.io/docs/zds/zoi/repositories), and these are:

Generic repos:

- Core: Essential packages and libraries; very common and well-maintained.
- Main: Important packages that don't fit in `core` but are essential for most users.
- Extra: New or niche packages; less common and may be less actively maintained.
- Community: User-submitted packages. New entries start here and may graduate to higher tiers.
- Test: Testing ground for new Zoi features and packages prior to release.
- Archive: Archived packages that are no longer maintained.

Note: Packages from `community`, `test`, and `archive` may carry higher risk. Zoi prints warnings where appropriate, [learn more](https://zillowe.qzz.io/docs/zds/zoi/repositories).

Other non-generic repos:

- Zillowe: Official packages from Zillowe Foundation.

## Adding a package

We welcome contributions to Zoidberg! To maintain high quality and consistency, all submissions must follow the official [Zoidberg Packaging Guidelines](https://zillowe.qzz.io/docs/zds/zoi/zoidberg-guidelines).

Create a [Merge Request](https://gitlab.com/zillowe/zillwen/zusty/zoidberg/-/merge_requests) to add a new package or an [Issue](https://gitlab.com/zillwen/zusty/zoidberg/-/issues) to request a new package (MRs/PRs are only acceptable on [GitLab](https://gitlab.com/zillwen/zusty/zoidberg), creating issues are acceptable on all Zoidberg [mirrors](#mirrors)).

Use [`@zillowe/hello`](https://github.com/zillowe/hello) as an example package, [learn more about packaging existing software](https://zillowe.qzz.io/docs/zds/zoi/creating-packages).

## Reporting Security Issues

We take the security of Zoidberg packages seriously. If you discover a vulnerability in a package, please report it by opening a Merge Request with a security advisory file.

1. **Create an Advisory:** Add a `.sec.yaml` file to the package directory.
2. **Use Temporary ID:** Name it `ZSA-YYYY-TEMP.sec.yaml`.
3. **Submit MR:** Open a Merge Request on [GitLab](https://gitlab.com/zillwen/zusty/zoidberg).

For more details, see the [Security Advisories guide](https://zillowe.qzz.io/docs/zds/zoi/guides/security-advisories).

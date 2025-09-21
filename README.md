# Zoidberg

The official Zoi packages repository

## Installing a package

To use Zoidberg packages with Zoi you'll need [Zoi](https://github.com/Zillowe/Zoi) installed first.

Zoidberg is the default package registry that comes with Zoi, could be different if you didn't use Zoi's [official binaries](https://github.com/Zillowe/Zoi/blob/main/SECURITY.md) or compiled your own with a different registry, [learn more](https://github.com/Zillowe/Zoi/blob/main/PACKAGING.md).

To check which registry you're using run this command:

```sh
zoi sync list
```

### Mirrors

If you want to use any of Zoidberg's mirrors run this:

```sh
zoi sync set {mirror}
# default (the packagers default one), gitlab, github, codeberg
```

Official mirrors:

- Primary: [GitLab](https://gitlab.com/Zillowe/Zillwen/Zusty/Zoidberg)
- Mirrors: [GitHub](https://github.com/Zillowe/Zoidberg), [Codeberg](https://codeberg.org/Zillowe/Zoidberg)

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
- Zillowe: Zillowe's own official packages.

Note: Packages from `community`, `test`, and `archive` may carry higher risk. Zoi prints warnings where appropriate, [learn more](https://zillowe.qzz.io/docs/zds/zoi/repositories).

Other non-generic repos:

- Zillowe: Official packages from Zillowe Foundation.

## Adding a package

Create a [Merge Request](https://gitlab.com/Zillwen/Zusty/Zoidberg/-/merge_requests) to add a new package or an [Issue](https://gitlab.com/Zillwen/Zusty/Zoidberg/-/issues) to request a new package (MRs/PRs are only acceptable on [GitLab](https://gitlab.com/Zillwen/Zusty/Zoidberg), creating issues are acceptable on all the git [mirrors](https://github.com/Zillowe/Zoi#-repositories-mirrors)).

Use [`@zillowe/hello`](https://github.com/Zillowe/Hello) as an example package, [learn more about packaging existing software](https://zillowe.qzz.io/docs/zds/zoi/creating-packages).

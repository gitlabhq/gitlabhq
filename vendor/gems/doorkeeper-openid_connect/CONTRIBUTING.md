# Contributing

## Workflow

We are using the [Feature Branch Workflow (also known as GitHub Flow)](https://guides.github.com/introduction/flow/), and prefer delivery as pull requests.

Our first line of defense is the [Travis CI](https://travis-ci.org/doorkeeper-gem/doorkeeper-openid_connect) build defined within [.travis.yml](.travis.yml) and triggered for every pull request.

Create a feature branch:

```sh
git checkout -B feature/contributing
```

## Creating Good Commits

The cardinal rule for creating good commits is to ensure there is only one
"logical change" per commit. Why is this an important rule?

* The smaller the amount of code being changed, the quicker & easier it is to
  review & identify potential flaws.

* If a change is found to be flawed later, it may be necessary to revert the
  broken commit. This is much easier to do if there are not other unrelated
  code changes entangled with the original commit.

* When troubleshooting problems using Git's bisect capability, small well
  defined changes will aid in isolating exactly where the code problem was
  introduced.

* When browsing history using Git annotate/blame, small well defined changes
  also aid in isolating exactly where & why a piece of code came from.

Things to avoid when creating commits:

* Mixing whitespace changes with functional code changes.
* Mixing two unrelated functional changes.
* Sending large new features in a single giant commit.

## Release process

- Bump version in `lib/doorkeeper/openid_connect/version.rb`.
- Update `CHANGELOG.md`.
- Commit all changes.
- Tag release and publish gem with `rake release`.
- [Publish a new release on GitHub](https://github.com/doorkeeper-gem/doorkeeper-openid_connect/releases/new), using the created tag and the new entries in `CHANGELOG.md`.

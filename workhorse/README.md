---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Workhorse

GitLab Workhorse is a smart reverse proxy for GitLab intended to handle
resource-intensive and long-running requests. It sits in front of Puma and
intercepts every HTTP request destined for and emitted from GitLab Rails.
Rails delegates requests to Workhorse and it takes responsibility for resource
intensive HTTP requests such as file downloads and uploads, git over HTTP
push/pull and git over HTTP archive downloads, which optimizes resource
utilization and improves request handling efficiency.

## Development Documentation

[Development documentation](https://docs.gitlab.com/ee/development/workhorse/).

## Project structure

| Directory | Description |
| --------- | ----------- |
| `cmd/` | 'Commands' that will ultimately be compiled into binaries. |
| `./` | Compiled binaries are created here. |
| `internal/` | Internal Go source code that is not intended to be used outside of the project/module. |
| `testdata/` | Contains various files to add in testing, such as .zip, .mp3 etc. |
| `_support/` | Scripts and tools that assist in development and/or testing. |

## Building

From the `workhorse/` directory, run `make` or `make all`.

## Testing

From the `workhorse/` directory, run `make test`.

## Merging and reviewing contributions

Contributions must be reviewed by at least one Workhorse maintainer.
The final merge must be performed by a maintainer.

It is preferable to request a review from a reviewer or a trainee maintainer
before passing it to a maintainer:

- [Maintainers](https://gitlab-org.gitlab.io/gitlab-roulette/?mode=show&visible=maintainer%7Cworkhorse)
- [Trainee Maintainers](https://gitlab-org.gitlab.io/gitlab-roulette/?mode=show&visible=trainee+maintainer%7Cworkhorse)
- [Reviewers](https://gitlab-org.gitlab.io/gitlab-roulette/?mode=show&visible=reviewer%7Cworkhorse)

## Licensing

See the `../LICENSE` file for licensing information as it pertains to files in
this repository.

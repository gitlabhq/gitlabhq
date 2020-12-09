# GitLab Workhorse

GitLab Workhorse is a smart reverse proxy for GitLab. It handles
"large" HTTP requests such as file downloads, file uploads, Git
push/pull and Git archive downloads.

Workhorse itself is not a feature, but there are [several features in
GitLab](doc/architecture/gitlab_features.md) that would not work efficiently without Workhorse.

## Canonical source

The canonical source for Workhorse is currently
[gitlab-org/gitlab-workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse).
As explained in https://gitlab.com/groups/gitlab-org/-/epics/4826, we
are in the process of moving the canonical source to
[gitlab-org/gitlab/workhorse](https://gitlab.com/gitlab-org/gitlab/tree/master/workhorse).

Until that transition is complete, changes (Merge Requests) for
Workhorse should be submitted at
[gitlab-org/gitlab-workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse).
Once merged, they will propagate to gitlab-org/gitlab/workhorse via
the usual Workhorse release process.

## Documentation

Workhorse documentation is available in the [`doc` folder of this repository](doc/).

* Architectural overview
  * [GitLab features that rely on Workhorse](doc/architecture/gitlab_features.md)
  * [Websocket channel support](doc/architecture/channel.md)
* Operating Workhorse
  * [Source installation](doc/operations/install.md)
  * [Workhorse configuration](doc/operations/configuration.md)
* [Contributing](CONTRIBUTING.md)
  * [Adding new features](doc/development/new_features.md)
  * [Testing your code](doc/development/tests.md)

## License

This code is distributed under the MIT license, see the [LICENSE](LICENSE) file.


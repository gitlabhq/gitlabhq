# GitLab-Workhorse development process

## Maintainers

GitLab-Workhorse has the following maintainers:

- Nick Thomas `@nick.thomas`
- Jacob Vosmaer `@jacobvosmaer-gitlab`
- Alessio Caiazza `@nolith`

This list is defined at https://about.gitlab.com/team/.

## Changelog

GitLab-Workhorse keeps a changelog which is generated when a new release
is created. The changelog is generated from entries that are included on each
merge request. To generate an entry on your branch run:
`_support/changelog "Change descriptions"`.

After the merge request is created, the ID of the merge request needs to be set
in the generated file. If you already know the merge request ID, run:
`_support/changelog -m <ID> "Change descriptions"`.

Any new merge request must contain either a new entry or a justification in the
merge request description why no changelog entry is needed.

## Merging and reviewing contributions

Contributions must be reviewed by at least one Workhorse maintainer.
The final merge must be performed by a maintainer.

## Releases

> Below we describe the legacy release process, from when Workhorse
> had its own repository. These instructions are still useful for
> security backports.

New versions of Workhorse can be released by one of the Workhorse
maintainers. The release process is:

-   pick a release branch. For x.y.0, use `master`. For all other
    versions (x.y.1, x.y.2 etc.) , use `x-y-stable`. Also see [below](#versioning)
-   run `make tag VERSION=x.y.z"` or `make signed_tag VERSION=x.y.z` on the release branch. This will
    compile the changelog, bump the VERSION file, and make a tag matching it.
-   push the branch and the tag to gitlab.com
-   the new version will only be deployed to `gitlab.com` if [`GITLAB_WORKHORSE_VERSION`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/GITLAB_WORKHORSE_VERSION) is updated accordingly;
    if applicable, please remind the person who originally asked for a new release to make this change
    (the MR should include a link back to the [version tag](https://gitlab.com/gitlab-org/gitlab-workhorse/-/tags) and a copy of the changelog)
-   the person who updates GITLAB_WORKHORSE_VERSION should also run `scripts/update-workhorse` after commiting the new GITLAB_WORKHORSE_VERSION. If they forget they will be reminded by CI.

## Security releases

Workhorse is included in the packages we create for GitLab, and each version of
GitLab specifies the version of Workhorse it uses in the `GITLAB_WORKHORSE_VERSION`
file, so security fixes in Workhorse are tightly coupled to the [general security release](https://about.gitlab.com/handbook/engineering/workflow/#security-issues)
workflow, with some elaborations to account for the changes happening across two
repositories. In particular, the Workhorse maintainer takes responsibility for
creating new patch versions of Workhorse that can be used in the security
release.

As security fixes are backported three releases in addition to master, and
changes need to happen across two repositories, up to eight merge requests, and
four Workhorse releases, can be required to fix a security issue in Workhorse.
This is a lot of overhead, so in general, it is better to fix security issues
without changing Workhorse. Where changes **are** necessary, this section
documents the necessary steps.

If you're working on a security fix in Workhorse, you need two sets of merge
requests:

* The fix itself, in the `gitlab-org/security/gitlab-workhorse` repository
* A merge request to change the version of workhorse included in the GitLab
  security release, in the `gitlab-org/security/gitlab` repository.

If the Workhorse maintainer isn't also a GitLab maintainer, reviews will need to
be split across several people. If changes to GitLab **code** are required in
addition to the change of Workhorse version, they both happen in the same merge
request.

Start by creating a single merge request targeting `master` in Workhorse. Ensure
you include a changelog! If code changes are needed in GitLab as well, create a
GitLab merge request targeting `master` at this point, but don't worry about the
`GITLAB_WORKHORSE_VERSION` file yet. 

Once the changes have passed review, the Workhorse maintainer will determine the
new versions of Workhorse that will be needed, and communicate that to the
author. To do this, examine the `GITLAB_WORKHORSE_VERSION` file on each GitLab
stable branch; for instance, if the security release consisted of GitLab
versions `12.10.1`, `12.9.2`, `12.8.3`, and `12.7.4`, we would see the following:

```
gitlab$ git fetch security master 12-10-stable-ee 12-9-stable-ee 12-8-stable-ee 12-7-stable-ee`
gitlab$ git show refs/remotes/security/master:GITLAB_WORKHORSE_VERSION
8.30.1
gitlab$ git show refs/remotes/security/12-10-stable-ee:GITLAB_WORKHORSE_VERSION
8.30.1
gitlab$ git show refs/remotes/security/12-9-stable-ee:GITLAB_WORKHORSE_VERSION
8.25.2
gitlab$ git show refs/remotes/security/12-8-stable-ee:GITLAB_WORKHORSE_VERSION
8.21.2
gitlab$ git show refs/remotes/security/12-7-stable-ee:GITLAB_WORKHORSE_VERSION
8.21.2
```

In this example, there are three distinct Workhorse stable branches to be
concerned with, plus Workhorse master: `8-30-stable`, `8-25-stable`, and
`8-21-stable`, and we can predict that we are going to need to create Workhorse
releases `8.30.2`, `8.25.3`, and `8.21.3`.

The author needs to create a merge request targeting each Workhorse stable
branch, and verify that the fix works once backported. They also need to create
(or update, if they already exist) GitLab merge requests, setting the
`GITLAB_WORKHORSE_VERSION` file to the predicted workhorse version, and assign
all the MRs back to the appropriate maintainer(s). The pipeline for the GitLab
MRs will fail until the Workhorse releases have been tagged; you can use the
`=workhorse_branch_name` syntax in the `GITLAB_WORKHORSE_VERSION` file to verify
that the MRs interact as expected, if necessary.

Once all involved maintainers are happy with the overall change, the Workhorse
maintainer will merge each of the Workhorse MRs and generate new Workhorse
releases from the stable branches. The tags will be present on the `security`
mirror and `dev.gitlab.org` **only** at this point.

Once the Workhorse tags exist, the GitLab maintainer ensures that all the GitLab
MRs are green and assigns those MRs on to the release bot.

The release managers merge the GitLab MRs, tag GitLab releases that reference
the new Workhorse tags, and release them in the usual way.

Once the security release is done, the Workhorse maintainer is responsible for
syncing the changes to the `gitlab-org/gitlab-workhorse` repository. Push the
changes to `master`, the new tags, and all the changes to the stable branches.

This process is quite involved, very manual, and extremely error-prone; work is
ongoing on automating it.

## Versioning

Workhorse uses a variation of SemVer. We don't use "normal" SemVer
because we have to be able to integrate into GitLab stable branches.

A version has the format MAJOR.MINOR.PATCH.

- Major and minor releases are tagged on the `master` branch
- If the change is backwards compatible, increment the MINOR counter
- If the change breaks compatibility, increment MAJOR and set MINOR to `0`
- Patch release tags must be made on stable branches
- Only make a patch release when targeting a GitLab stable branch

This means that tags that end in `.0` (e.g. `8.5.0`) must always be on
the master branch, and tags that end in anthing other than `.0` (e.g.
`8.5.2`) must always be on a stable branch.

> The reason we do this is that SemVer suggests something like a
> refactoring constitutes a "patch release", while the GitLab stable
> branch quality standards do not allow for back-porting refactorings
> into a stable branch.

# Gitlab::Git test repository

This repository is used by (some of) the tests in spec/lib/gitlab/git.

Do not add new large files to this repository. Otherwise we needlessly
inflate the size of the gitlab-ce repository.

## How to make changes to this repository

- (if needed) clone `https://gitlab.com/gitlab-org/gitlab-foss.git` to your local machine
- clone `gitlab-ce/spec/support/gitlab-git-test.git` locally (i.e. clone from your hard drive, not from the internet)
- make changes in your local clone of gitlab-git-test
- run `git push` which will push to your local source `gitlab-ce/spec/support/gitlab-git-test.git`
- in gitlab-ce: run `spec/support/prepare-gitlab-git-test-for-commit`
- in gitlab-ce: `git add spec/support/helpers/seed_repo.rb spec/support/gitlab-git-test.git`
- commit your changes in gitlab-ce

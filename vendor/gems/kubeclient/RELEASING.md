# Releasing Kubeclient

## Versioning
Kubeclient release versioning follows [SemVer](https://semver.org/).
At some point in time it is decided to release version x.y.z.

```bash
RELEASE_BRANCH="master"
```

## 0. (once) Install gem-release, needed for several commands here:

```bash
gem install gem-release
```

## 1. PR(s) for changelog & bump

Edit `CHANGELOG.md` as necessary.  Even if all included changes remembered to update it, you should replace "Unreleased" section header with appropriate "x.y.z — 20yy-mm-dd" header.

Bump `lib/kubeclient/version.rb` manually, or by using:
```bash
RELEASE_VERSION=x.y.z

git checkout -b "release-$RELEASE_VERSION" $RELEASE_BRANCH
# Won't work with uncommitted changes, you have to commit the changelog first.
gem bump --version $RELEASE_VERSION
git show # View version bump change.
```

Open a PR with target branch $RELEASE_BRANCH and get it reviewed & merged (if open for long, remember to update date in CHANGELOG to actual day of release).

## 2. (once) Grabbing an authentication token for rubygems.org api
```bash
RUBYGEMS_USERNAME=bob
curl -u $RUBYGEMS_USERNAME https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials; chmod 0600 ~/.gem/credentials

cat ~/.gem/credentials
# Should look like this:
:rubygems_api_key: ****
```

## 3. Actual release

Make sure we're locally after the bump PR *merge commit*:
```bash
git checkout $RELEASE_BRANCH
git status # Make sure there are no local changes
git pull --ff-only https://github.com/abonas/kubeclient $RELEASE_BRANCH
git log -n1
```

Last sanity check:
```bash
bundle install
bundle exec rake test rubocop
```

Create and push the tag:
```bash
gem tag --no-push
git push --tags --dry-run https://github.com/abonas/kubeclient  # Check for unexpected tags
git push --tags https://github.com/abonas/kubeclient
```

Release onto rubygems.org:
```bash
gem release
```

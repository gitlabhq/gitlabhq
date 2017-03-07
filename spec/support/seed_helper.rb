# This file is specific to specs in spec/lib/gitlab/git/

SEED_REPOSITORY_PATH   = File.expand_path('../../tmp/repositories', __dir__)
TEST_REPO_PATH         = File.join(SEED_REPOSITORY_PATH, 'gitlab-git-test.git')
TEST_NORMAL_REPO_PATH  = File.join(SEED_REPOSITORY_PATH, "not-bare-repo.git")
TEST_MUTABLE_REPO_PATH = File.join(SEED_REPOSITORY_PATH, "mutable-repo.git")
TEST_BROKEN_REPO_PATH  = File.join(SEED_REPOSITORY_PATH, "broken-repo.git")

module SeedHelper
  GITLAB_URL = "https://gitlab.com/gitlab-org/gitlab-git-test.git".freeze

  def ensure_seeds
    if File.exist?(SEED_REPOSITORY_PATH)
      FileUtils.rm_r(SEED_REPOSITORY_PATH)
    end

    FileUtils.mkdir_p(SEED_REPOSITORY_PATH)

    create_bare_seeds
    create_normal_seeds
    create_mutable_seeds
    create_broken_seeds
    create_git_attributes
    create_invalid_git_attributes
  end

  def create_bare_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone --bare #{GITLAB_URL}),
           chdir: SEED_REPOSITORY_PATH,
           out:   '/dev/null',
           err:   '/dev/null')
  end

  def create_normal_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone #{TEST_REPO_PATH} #{TEST_NORMAL_REPO_PATH}),
           out: '/dev/null',
           err: '/dev/null')
  end

  def create_mutable_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone #{TEST_REPO_PATH} #{TEST_MUTABLE_REPO_PATH}),
           out: '/dev/null',
           err: '/dev/null')

    system(git_env, *%w(git branch -t feature origin/feature),
           chdir: TEST_MUTABLE_REPO_PATH, out: '/dev/null', err: '/dev/null')

    system(git_env, *%W(#{Gitlab.config.git.bin_path} remote add expendable #{GITLAB_URL}),
           chdir: TEST_MUTABLE_REPO_PATH, out: '/dev/null', err: '/dev/null')
  end

  def create_broken_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone --bare #{TEST_REPO_PATH} #{TEST_BROKEN_REPO_PATH}),
           out: '/dev/null',
           err: '/dev/null')

    refs_path = File.join(TEST_BROKEN_REPO_PATH, 'refs')

    FileUtils.rm_r(refs_path)
  end

  def create_git_attributes
    dir = File.join(SEED_REPOSITORY_PATH, 'with-git-attributes.git', 'info')

    FileUtils.mkdir_p(dir)

    File.open(File.join(dir, 'attributes'), 'w') do |handle|
      handle.write <<-EOF.strip
# This is a comment, it should be ignored.

*.txt     text
*.jpg     -text
*.sh      eol=lf gitlab-language=shell
*.haml.*  gitlab-language=haml
foo/bar.* foo
*.cgi     key=value?p1=v1&p2=v2
/*.png    gitlab-language=png
*.binary  binary

# This uses a tab instead of spaces to ensure the parser also supports this.
*.md\tgitlab-language=markdown
bla/bla.txt
      EOF
    end
  end

  def create_invalid_git_attributes
    dir = File.join(SEED_REPOSITORY_PATH, 'with-invalid-git-attributes.git', 'info')

    FileUtils.mkdir_p(dir)

    enc = Encoding::UTF_16

    File.open(File.join(dir, 'attributes'), 'w', encoding: enc) do |handle|
      handle.write('# hello'.encode(enc))
    end
  end

  # Prevent developer git configurations from being persisted to test
  # repositories
  def git_env
    { 'GIT_TEMPLATE_DIR' => '' }
  end
end

RSpec.configure do |config|
  config.include SeedHelper, :seed_helper

  config.before(:all, :seed_helper) do
    ensure_seeds
  end
end

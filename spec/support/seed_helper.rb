require_relative 'test_env'

# This file is specific to specs in spec/lib/gitlab/git/

SEED_STORAGE_PATH      = TestEnv.repos_path
TEST_REPO_PATH         = 'gitlab-git-test.git'.freeze
TEST_NORMAL_REPO_PATH  = 'not-bare-repo.git'.freeze
TEST_MUTABLE_REPO_PATH = 'mutable-repo.git'.freeze
TEST_BROKEN_REPO_PATH  = 'broken-repo.git'.freeze

module SeedHelper
  GITLAB_GIT_TEST_REPO_URL = File.expand_path('../gitlab-git-test.git', __FILE__).freeze

  def ensure_seeds
    if File.exist?(SEED_STORAGE_PATH)
      FileUtils.rm_r(SEED_STORAGE_PATH)
    end

    FileUtils.mkdir_p(SEED_STORAGE_PATH)

    create_bare_seeds
    create_normal_seeds
    create_mutable_seeds
    create_broken_seeds
    create_git_attributes
    create_invalid_git_attributes
  end

  def create_bare_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone --bare #{GITLAB_GIT_TEST_REPO_URL}),
           chdir: SEED_STORAGE_PATH,
           out:   '/dev/null',
           err:   '/dev/null')
  end

  def create_normal_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone #{TEST_REPO_PATH} #{TEST_NORMAL_REPO_PATH}),
           chdir: SEED_STORAGE_PATH,
           out: '/dev/null',
           err: '/dev/null')
  end

  def create_mutable_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone --bare #{TEST_REPO_PATH} #{TEST_MUTABLE_REPO_PATH}),
           chdir: SEED_STORAGE_PATH,
           out: '/dev/null',
           err: '/dev/null')

    mutable_repo_full_path = File.join(SEED_STORAGE_PATH, TEST_MUTABLE_REPO_PATH)
    system(git_env, *%W(#{Gitlab.config.git.bin_path} branch -t feature origin/feature),
           chdir: mutable_repo_full_path, out: '/dev/null', err: '/dev/null')

    system(git_env, *%W(#{Gitlab.config.git.bin_path} remote add expendable #{GITLAB_GIT_TEST_REPO_URL}),
           chdir: mutable_repo_full_path, out: '/dev/null', err: '/dev/null')
  end

  def create_broken_seeds
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone --bare #{TEST_REPO_PATH} #{TEST_BROKEN_REPO_PATH}),
           chdir: SEED_STORAGE_PATH,
           out: '/dev/null',
           err: '/dev/null')

    refs_path = File.join(SEED_STORAGE_PATH, TEST_BROKEN_REPO_PATH, 'refs')

    FileUtils.rm_r(refs_path)
  end

  def create_git_attributes
    dir = File.join(SEED_STORAGE_PATH, 'with-git-attributes.git', 'info')

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
    dir = File.join(SEED_STORAGE_PATH, 'with-invalid-git-attributes.git', 'info')

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

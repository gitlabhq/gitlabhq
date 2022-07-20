# frozen_string_literal: true

require_relative 'test_env'

# This file is specific to specs in spec/lib/gitlab/git/

SEED_STORAGE_PATH      = Gitlab::GitalyClient::StorageSettings.allow_disk_access { TestEnv.repos_path }
TEST_REPO_PATH         = 'gitlab-git-test.git'
TEST_NORMAL_REPO_PATH  = 'not-bare-repo.git'
TEST_MUTABLE_REPO_PATH = 'mutable-repo.git'
TEST_BROKEN_REPO_PATH  = 'broken-repo.git'

module SeedHelper
  GITLAB_GIT_TEST_REPO_URL = File.expand_path('../gitlab-git-test.git', __dir__)

  def ensure_seeds
    if File.exist?(SEED_STORAGE_PATH)
      FileUtils.rm_r(SEED_STORAGE_PATH)
    end

    FileUtils.mkdir_p(SEED_STORAGE_PATH)

    create_bare_seeds
    create_normal_seeds
    create_mutable_seeds
    create_broken_seeds
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
end

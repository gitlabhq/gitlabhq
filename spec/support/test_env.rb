require 'rspec/mocks'

module TestEnv
  extend self

  # When developing the seed repository, comment out the branch you will modify.
  BRANCH_SHA = {
    'not-merged-branch'                  => 'b83d6e3',
    'branch-merged'                      => '498214d',
    'empty-branch'                       => '7efb185',
    'ends-with.json'                     => '98b0d8b',
    'flatten-dir'                        => 'e56497b',
    'feature'                            => '0b4bc9a',
    'feature_conflict'                   => 'bb5206f',
    'fix'                                => '48f0be4',
    'improve/awesome'                    => '5937ac0',
    'markdown'                           => '0ed8c6c',
    'lfs'                                => 'be93687',
    'master'                             => 'b83d6e3',
    'merge-test'                         => '5937ac0',
    "'test'"                             => 'e56497b',
    'orphaned-branch'                    => '45127a9',
    'binary-encoding'                    => '7b1cf43',
    'gitattributes'                      => '5a62481',
    'expand-collapse-diffs'              => '4842455',
    'symlink-expand-diff'                => '81e6355',
    'expand-collapse-files'              => '025db92',
    'expand-collapse-lines'              => '238e82d',
    'video'                              => '8879059',
    'crlf-diff'                          => '5938907',
    'conflict-start'                     => '824be60',
    'conflict-resolvable'                => '1450cd6',
    'conflict-binary-file'               => '259a6fb',
    'conflict-contains-conflict-markers' => '78a3086',
    'conflict-missing-side'              => 'eb227b3',
    'conflict-non-utf8'                  => 'd0a293c',
    'conflict-too-large'                 => '39fa04f',
    'deleted-image-test'                 => '6c17798'
  }

  # gitlab-test-fork is a fork of gitlab-fork, but we don't necessarily
  # need to keep all the branches in sync.
  # We currently only need a subset of the branches
  FORKED_BRANCH_SHA = {
    'add-submodule-version-bump' => '3f547c0',
    'master'                     => '5937ac0',
    'remove-submodule'           => '2a33e0c',
    'conflict-resolvable-fork'   => '404fa3f'
  }

  # Test environment
  #
  # See gitlab.yml.example test section for paths
  #
  def init(opts = {})
    # Disable mailer for spinach tests
    disable_mailer if opts[:mailer] == false

    clean_test_path

    FileUtils.mkdir_p(repos_path)
    FileUtils.mkdir_p(backup_path)

    # Setup GitLab shell for test instance
    setup_gitlab_shell

    # Create repository for FactoryGirl.create(:project)
    setup_factory_repo

    # Create repository for FactoryGirl.create(:forked_project_with_submodules)
    setup_forked_repo
  end

  def disable_mailer
    allow_any_instance_of(NotificationService).to receive(:mailer).
      and_return(double.as_null_object)
  end

  def enable_mailer
    allow_any_instance_of(NotificationService).to receive(:mailer).
      and_call_original
  end

  def disable_pre_receive
    allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, nil])
  end

  # Clean /tmp/tests
  #
  # Keeps gitlab-shell and gitlab-test
  def clean_test_path
    tmp_test_path = Rails.root.join('tmp', 'tests', '**')

    Dir[tmp_test_path].each do |entry|
      unless File.basename(entry) =~ /\Agitlab-(shell|test|test-fork)\z/
        FileUtils.rm_rf(entry)
      end
    end
  end

  def setup_gitlab_shell
    unless File.directory?(Gitlab.config.gitlab_shell.path)
      unless system('rake', 'gitlab:shell:install')
        raise 'Can`t clone gitlab-shell'
      end
    end
  end

  def setup_factory_repo
    setup_repo(factory_repo_path, factory_repo_path_bare, factory_repo_name,
               BRANCH_SHA)
  end

  # This repo has a submodule commit that is not present in the main test
  # repository.
  def setup_forked_repo
    setup_repo(forked_repo_path, forked_repo_path_bare, forked_repo_name,
               FORKED_BRANCH_SHA)
  end

  def setup_repo(repo_path, repo_path_bare, repo_name, branch_sha)
    clone_url = "https://gitlab.com/gitlab-org/#{repo_name}.git"

    unless File.directory?(repo_path)
      system(*%W(#{Gitlab.config.git.bin_path} clone -q #{clone_url} #{repo_path}))
    end

    set_repo_refs(repo_path, branch_sha)

    # We must copy bare repositories because we will push to them.
    system(git_env, *%W(#{Gitlab.config.git.bin_path} clone -q --bare #{repo_path} #{repo_path_bare}))
  end

  def copy_repo(project)
    base_repo_path = File.expand_path(factory_repo_path_bare)
    target_repo_path = File.expand_path(project.repository_storage_path + "/#{project.namespace.path}/#{project.path}.git")
    FileUtils.mkdir_p(target_repo_path)
    FileUtils.cp_r("#{base_repo_path}/.", target_repo_path)
    FileUtils.chmod_R 0755, target_repo_path
    set_repo_refs(target_repo_path, BRANCH_SHA)
  end

  def repos_path
    Gitlab.config.repositories.storages.default
  end

  def backup_path
    Gitlab.config.backup.path
  end

  def copy_forked_repo_with_submodules(project)
    base_repo_path = File.expand_path(forked_repo_path_bare)
    target_repo_path = File.expand_path(project.repository_storage_path + "/#{project.namespace.path}/#{project.path}.git")
    FileUtils.mkdir_p(target_repo_path)
    FileUtils.cp_r("#{base_repo_path}/.", target_repo_path)
    FileUtils.chmod_R 0755, target_repo_path
    set_repo_refs(target_repo_path, FORKED_BRANCH_SHA)
  end

  # When no cached assets exist, manually hit the root path to create them
  #
  # Otherwise they'd be created by the first test, often timing out and
  # causing a transient test failure
  def warm_asset_cache
    return if warm_asset_cache?
    return unless defined?(Capybara)

    Capybara.current_session.driver.visit '/'
  end

  def warm_asset_cache?
    cache = Rails.root.join(*%w(tmp cache assets test))
    Dir.exist?(cache) && Dir.entries(cache).length > 2
  end

  private

  def factory_repo_path
    @factory_repo_path ||= Rails.root.join('tmp', 'tests', factory_repo_name)
  end

  def factory_repo_path_bare
    "#{factory_repo_path}_bare"
  end

  def factory_repo_name
    'gitlab-test'
  end

  def forked_repo_path
    @forked_repo_path ||= Rails.root.join('tmp', 'tests', forked_repo_name)
  end

  def forked_repo_path_bare
    "#{forked_repo_path}_bare"
  end

  def forked_repo_name
    'gitlab-test-fork'
  end

  # Prevent developer git configurations from being persisted to test
  # repositories
  def git_env
    { 'GIT_TEMPLATE_DIR' => '' }
  end

  def set_repo_refs(repo_path, branch_sha)
    instructions = branch_sha.map {|branch, sha| "update refs/heads/#{branch}\x00#{sha}\x00" }.join("\x00") << "\x00"
    update_refs = %W(#{Gitlab.config.git.bin_path} update-ref --stdin -z)
    reset = proc do
      IO.popen(update_refs, "w") {|io| io.write(instructions) }
      $?.success?
    end

    Dir.chdir(repo_path) do
      # Try to reset without fetching to avoid using the network.
      unless reset.call
        raise 'Could not fetch test seed repository.' unless system(*%W(#{Gitlab.config.git.bin_path} fetch origin))
        raise 'The fetched test seed does not contain the required revision.' unless reset.call
      end
    end
  end
end

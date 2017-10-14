require 'rspec/mocks'

module TestEnv
  extend self

  # When developing the seed repository, comment out the branch you will modify.
  BRANCH_SHA = {
    'signed-commits'                     => '2d1096e',
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
    'add-balsamiq-file'                  => 'b89b56d',
    'crlf-diff'                          => '5938907',
    'conflict-start'                     => '824be60',
    'conflict-resolvable'                => '1450cd6',
    'conflict-binary-file'               => '259a6fb',
    'conflict-contains-conflict-markers' => '78a3086',
    'conflict-missing-side'              => 'eb227b3',
    'conflict-non-utf8'                  => 'd0a293c',
    'conflict-too-large'                 => '39fa04f',
    'deleted-image-test'                 => '6c17798',
    'wip'                                => 'b9238ee',
    'csv'                                => '3dd0896',
    'v1.1.0'                             => 'b83d6e3',
    'add-ipython-files'                  => '93ee732',
    'add-pdf-file'                       => 'e774ebd',
    'add-pdf-text-binary'                => '79faa7b'
  }.freeze

  # gitlab-test-fork is a fork of gitlab-fork, but we don't necessarily
  # need to keep all the branches in sync.
  # We currently only need a subset of the branches
  FORKED_BRANCH_SHA = {
    'add-submodule-version-bump' => '3f547c0',
    'master'                     => '5937ac0',
    'remove-submodule'           => '2a33e0c',
    'conflict-resolvable-fork'   => '404fa3f'
  }.freeze

  TMP_TEST_PATH = Rails.root.join('tmp', 'tests', '**')

  # Test environment
  #
  # See gitlab.yml.example test section for paths
  #
  def init(opts = {})
    # Disable mailer for spinach tests
    disable_mailer if opts[:mailer] == false

    clean_test_path

    # Setup GitLab shell for test instance
    setup_gitlab_shell

    setup_gitaly

    # Create repository for FactoryGirl.create(:project)
    setup_factory_repo

    # Create repository for FactoryGirl.create(:forked_project_with_submodules)
    setup_forked_repo
  end

  def cleanup
    stop_gitaly
  end

  def disable_mailer
    allow_any_instance_of(NotificationService).to receive(:mailer)
      .and_return(double.as_null_object)
  end

  def enable_mailer
    allow_any_instance_of(NotificationService).to receive(:mailer)
      .and_call_original
  end

  def disable_pre_receive
    allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, nil])
  end

  # Clean /tmp/tests
  #
  # Keeps gitlab-shell and gitlab-test
  def clean_test_path
    Dir[TMP_TEST_PATH].each do |entry|
      unless File.basename(entry) =~ /\A(gitaly|gitlab-(shell|test|test_bare|test-fork|test-fork_bare))\z/
        FileUtils.rm_rf(entry)
      end
    end

    FileUtils.mkdir_p(repos_path)
    FileUtils.mkdir_p(backup_path)
    FileUtils.mkdir_p(pages_path)
  end

  def clean_gitlab_test_path
    Dir[TMP_TEST_PATH].each do |entry|
      if File.basename(entry) =~ /\A(gitlab-(test|test_bare|test-fork|test-fork_bare))\z/
        FileUtils.rm_rf(entry)
      end
    end
  end

  def setup_gitlab_shell
    puts "\n==> Setting up Gitlab Shell..."
    start = Time.now
    gitlab_shell_dir = Gitlab.config.gitlab_shell.path
    shell_needs_update = component_needs_update?(gitlab_shell_dir,
      Gitlab::Shell.version_required)

    unless !shell_needs_update || system('rake', 'gitlab:shell:install')
      puts "\nGitLab Shell failed to install, cleaning up #{gitlab_shell_dir}!\n"
      FileUtils.rm_rf(gitlab_shell_dir)
      exit 1
    end

    puts "    GitLab Shell setup in #{Time.now - start} seconds...\n"
  end

  def setup_gitaly
    puts "\n==> Setting up Gitaly..."
    start = Time.now
    socket_path = Gitlab::GitalyClient.address('default').sub(/\Aunix:/, '')
    gitaly_dir = File.dirname(socket_path)

    if gitaly_dir_stale?(gitaly_dir)
      puts "    Gitaly is outdated, cleaning up #{gitaly_dir}!"
      FileUtils.rm_rf(gitaly_dir)
    end

    gitaly_needs_update = component_needs_update?(gitaly_dir,
      Gitlab::GitalyClient.expected_server_version)

    unless !gitaly_needs_update || system('rake', "gitlab:gitaly:install[#{gitaly_dir}]")
      puts "\nGitaly failed to install, cleaning up #{gitaly_dir}!\n"
      FileUtils.rm_rf(gitaly_dir)
      exit 1
    end

    start_gitaly(gitaly_dir)
    puts "    Gitaly setup in #{Time.now - start} seconds...\n"
  end

  def gitaly_dir_stale?(dir)
    gitaly_executable = File.join(dir, 'gitaly')
    return false unless File.exist?(gitaly_executable)

    File.mtime(gitaly_executable) < File.mtime(Rails.root.join('GITALY_SERVER_VERSION'))
  end

  def start_gitaly(gitaly_dir)
    if ENV['CI'].present?
      # Gitaly has been spawned outside this process already
      return
    end

    spawn_script = Rails.root.join('scripts/gitaly-test-spawn').to_s
    @gitaly_pid = Bundler.with_original_env { IO.popen([spawn_script], &:read).to_i }
  end

  def stop_gitaly
    return unless @gitaly_pid

    Process.kill('KILL', @gitaly_pid)
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

  def setup_repo(repo_path, repo_path_bare, repo_name, refs)
    clone_url = "https://gitlab.com/gitlab-org/#{repo_name}.git"

    unless File.directory?(repo_path)
      system(*%W(#{Gitlab.config.git.bin_path} clone -q #{clone_url} #{repo_path}))
    end

    set_repo_refs(repo_path, refs)

    unless File.directory?(repo_path_bare)
      # We must copy bare repositories because we will push to them.
      system(git_env, *%W(#{Gitlab.config.git.bin_path} clone -q --bare #{repo_path} #{repo_path_bare}))
    end
  end

  def copy_repo(project, bare_repo:, refs:)
    target_repo_path = File.expand_path(project.repository_storage_path + "/#{project.full_path}.git")
    FileUtils.mkdir_p(target_repo_path)
    FileUtils.cp_r("#{File.expand_path(bare_repo)}/.", target_repo_path)
    FileUtils.chmod_R 0755, target_repo_path
    set_repo_refs(target_repo_path, refs)
  end

  def repos_path
    Gitlab.config.repositories.storages.default['path']
  end

  def backup_path
    Gitlab.config.backup.path
  end

  def pages_path
    Gitlab.config.pages.path
  end

  # When no cached assets exist, manually hit the root path to create them
  #
  # Otherwise they'd be created by the first test, often timing out and
  # causing a transient test failure
  def eager_load_driver_server
    return unless defined?(Capybara)

    puts "Starting the Capybara driver server..."
    Capybara.current_session.visit '/'
  end

  def factory_repo_path_bare
    "#{factory_repo_path}_bare"
  end

  def forked_repo_path_bare
    "#{forked_repo_path}_bare"
  end

  def with_empty_bare_repository(name = nil)
    path = Rails.root.join('tmp/tests', name || 'empty-bare-repository').to_s

    yield(Rugged::Repository.init_at(path, :bare))
  ensure
    FileUtils.rm_rf(path)
  end

  private

  def factory_repo_path
    @factory_repo_path ||= Rails.root.join('tmp', 'tests', factory_repo_name)
  end

  def factory_repo_name
    'gitlab-test'
  end

  def forked_repo_path
    @forked_repo_path ||= Rails.root.join('tmp', 'tests', forked_repo_name)
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
    instructions = branch_sha.map { |branch, sha| "update refs/heads/#{branch}\x00#{sha}\x00" }.join("\x00") << "\x00"
    update_refs = %W(#{Gitlab.config.git.bin_path} update-ref --stdin -z)
    reset = proc do
      Dir.chdir(repo_path) do
        IO.popen(update_refs, "w") { |io| io.write(instructions) }
        $?.success?
      end
    end

    # Try to reset without fetching to avoid using the network.
    unless reset.call
      raise 'Could not fetch test seed repository.' unless system(*%W(#{Gitlab.config.git.bin_path} -C #{repo_path} fetch origin))

      # Before we used Git clone's --mirror option, bare repos could end up
      # with missing refs, clearing them and retrying should fix the issue.
      cleanup && clean_gitlab_test_path && init unless reset.call
    end
  end

  def component_needs_update?(component_folder, expected_version)
    version = File.read(File.join(component_folder, 'VERSION')).strip

    # Notice that this will always yield true when using branch versions
    # (`=branch_name`), but that actually makes sure the server is always based
    # on the latest branch revision.
    version != expected_version
  rescue Errno::ENOENT
    true
  end
end

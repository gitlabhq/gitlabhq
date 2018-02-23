require 'rspec/mocks'
require 'toml-rb'

module TestEnv
  extend self

  ComponentFailedToInstallError = Class.new(StandardError)

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
    'merged-target'                      => '21751bf',
    'markdown'                           => '0ed8c6c',
    'lfs'                                => '55bc176',
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
    'add-pdf-text-binary'                => '79faa7b',
    'add_images_and_changes'             => '010d106'
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
    unless Rails.env.test?
      puts "\nTestEnv.init can only be run if `RAILS_ENV` is set to 'test' not '#{Rails.env}'!\n"
      exit 1
    end

    # Disable mailer for spinach tests
    disable_mailer if opts[:mailer] == false

    clean_test_path

    # Setup GitLab shell for test instance
    setup_gitlab_shell

    setup_gitaly

    # Create repository for FactoryBot.create(:project)
    setup_factory_repo

    # Create repository for FactoryBot.create(:forked_project_with_submodules)
    setup_forked_repo
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
    FileUtils.mkdir_p(artifacts_path)
  end

  def clean_gitlab_test_path
    Dir[TMP_TEST_PATH].each do |entry|
      if File.basename(entry) =~ /\A(gitlab-(test|test_bare|test-fork|test-fork_bare))\z/
        FileUtils.rm_rf(entry)
      end
    end
  end

  def setup_gitlab_shell
    component_timed_setup('GitLab Shell',
      install_dir: Gitlab.config.gitlab_shell.path,
      version: Gitlab::Shell.version_required,
      task: 'gitlab:shell:install')
  end

  def setup_gitaly
    socket_path = Gitlab::GitalyClient.address('default').sub(/\Aunix:/, '')
    gitaly_dir = File.dirname(socket_path)

    component_timed_setup('Gitaly',
      install_dir: gitaly_dir,
      version: Gitlab::GitalyClient.expected_server_version,
      task: "gitlab:gitaly:install[#{gitaly_dir}]") do

      # Always re-create config, in case it's outdated. This is fast anyway.
      Gitlab::SetupHelper.create_gitaly_configuration(gitaly_dir, force: true)

      start_gitaly(gitaly_dir)
    end
  end

  def start_gitaly(gitaly_dir)
    if ENV['CI'].present?
      # Gitaly has been spawned outside this process already
      return
    end

    spawn_script = Rails.root.join('scripts/gitaly-test-spawn').to_s
    @gitaly_pid = Bundler.with_original_env { IO.popen([spawn_script], &:read).to_i }
    Kernel.at_exit { stop_gitaly }

    wait_gitaly
  end

  def wait_gitaly
    sleep_time = 10
    sleep_interval = 0.1
    socket = Gitlab::GitalyClient.address('default').sub('unix:', '')

    Integer(sleep_time / sleep_interval).times do
      begin
        Socket.unix(socket)
        return
      rescue
        sleep sleep_interval
      end
    end

    raise "could not connect to gitaly at #{socket.inspect} after #{sleep_time} seconds"
  end

  def stop_gitaly
    return unless @gitaly_pid

    Process.kill('KILL', @gitaly_pid)
  rescue Errno::ESRCH
    # The process can already be gone if the test run was INTerrupted.
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
    target_repo_path = File.expand_path(project.repository_storage_path + "/#{project.disk_path}.git")
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

  def artifacts_path
    Gitlab.config.artifacts.storage_path
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
      clean_gitlab_test_path && init unless reset.call
    end
  end

  def component_timed_setup(component, install_dir:, version:, task:)
    puts "\n==> Setting up #{component}..."
    start = Time.now

    ensure_component_dir_name_is_correct!(component, install_dir)

    # On CI, once installed, components never need update
    return if File.exist?(install_dir) && ENV['CI']

    if component_needs_update?(install_dir, version)
      # Cleanup the component entirely to ensure we start fresh
      FileUtils.rm_rf(install_dir)

      unless system('rake', task)
        raise ComponentFailedToInstallError
      end
    end

    yield if block_given?

  rescue ComponentFailedToInstallError
    puts "\n#{component} failed to install, cleaning up #{install_dir}!\n"
    FileUtils.rm_rf(install_dir)
    exit 1
  ensure
    puts "    #{component} setup in #{Time.now - start} seconds...\n"
  end

  def ensure_component_dir_name_is_correct!(component, path)
    actual_component_dir_name = File.basename(path)
    expected_component_dir_name = component.parameterize

    unless actual_component_dir_name == expected_component_dir_name
      puts "    #{component} install dir should be named '#{expected_component_dir_name}', not '#{actual_component_dir_name}' (full install path given was '#{path}')!\n"
      exit 1
    end
  end

  def component_needs_update?(component_folder, expected_version)
    # Allow local overrides of the component for tests during development
    return false if Rails.env.test? && File.symlink?(component_folder)

    version = File.read(File.join(component_folder, 'VERSION')).strip

    # Notice that this will always yield true when using branch versions
    # (`=branch_name`), but that actually makes sure the server is always based
    # on the latest branch revision.
    version != expected_version
  rescue Errno::ENOENT
    true
  end
end

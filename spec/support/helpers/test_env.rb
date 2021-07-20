# frozen_string_literal: true

require 'parallel'

module TestEnv
  extend self

  ComponentFailedToInstallError = Class.new(StandardError)

  # When developing the seed repository, comment out the branch you will modify.
  BRANCH_SHA = {
    'signed-commits'                     => '6101e87',
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
    'diff-files-symlink-to-image'        => '8cfca84',
    'diff-files-image-to-symlink'        => '3e94fda',
    'diff-files-symlink-to-text'         => '689815e',
    'diff-files-text-to-symlink'         => '5e2c270',
    'expand-collapse-files'              => '025db92',
    'expand-collapse-lines'              => '238e82d',
    'pages-deploy'                       => '7897d5b',
    'pages-deploy-target'                => '7975be0',
    'audio'                              => 'c3c21fd',
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
    'add-ipython-files'                  => 'f6b7a70',
    'add-pdf-file'                       => 'e774ebd',
    'squash-large-files'                 => '54cec52',
    'add-pdf-text-binary'                => '79faa7b',
    'add_images_and_changes'             => '010d106',
    'update-gitlab-shell-v-6-0-1'        => '2f61d70',
    'update-gitlab-shell-v-6-0-3'        => 'de78448',
    'merge-commit-analyze-before'        => '1adbdef',
    'merge-commit-analyze-side-branch'   => '8a99451',
    'merge-commit-analyze-after'         => '646ece5',
    'snippet/single-file'                => '43e4080aaa14fc7d4b77ee1f5c9d067d5a7df10e',
    'snippet/multiple-files'             => '40232f7eb98b3f221886432def6e8bab2432add9',
    'snippet/rename-and-edit-file'       => '220a1e4b4dff37feea0625a7947a4c60fbe78365',
    'snippet/edit-file'                  => 'c2f074f4f26929c92795a75775af79a6ed6d8430',
    'snippet/no-files'                   => '671aaa842a4875e5f30082d1ab6feda345fdb94d',
    '2-mb-file'                          => 'bf12d25',
    'before-create-delete-modify-move'   => '845009f',
    'between-create-delete-modify-move'  => '3f5f443',
    'after-create-delete-modify-move'    => 'ba3faa7',
    'with-codeowners'                    => '219560e',
    'submodule_inside_folder'            => 'b491b92',
    'png-lfs'                            => 'fe42f41',
    'sha-starting-with-large-number'     => '8426165',
    'invalid-utf8-diff-paths'            => '99e4853',
    'compare-with-merge-head-source'     => 'f20a03d',
    'compare-with-merge-head-target'     => '2f1e176',
    'trailers'                           => 'f0a5ed6'
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

  TMP_TEST_PATH = Rails.root.join('tmp', 'tests').freeze
  REPOS_STORAGE = 'default'
  SECOND_STORAGE_PATH = Rails.root.join('tmp', 'tests', 'second_storage')
  SETUP_METHODS = %i[setup_gitaly setup_gitlab_shell setup_workhorse setup_factory_repo setup_forked_repo].freeze

  # Can be overriden
  def setup_methods
    SETUP_METHODS
  end

  # Test environment
  #
  # See gitlab.yml.example test section for paths
  #
  def init
    unless Rails.env.test?
      puts "\nTestEnv.init can only be run if `RAILS_ENV` is set to 'test' not '#{Rails.env}'!\n"
      exit 1
    end

    start = Time.now
    # Disable mailer for spinach tests
    clean_test_path

    # Install components in parallel as most of the setup is I/O.
    Parallel.each(setup_methods) do |method|
      public_send(method)
    end

    post_init

    puts "\nTest environment set up in #{Time.now - start} seconds"
  end

  # Can be overriden
  def post_init
    start_gitaly(gitaly_dir)
  end

  # Clean /tmp/tests
  #
  # Keeps gitlab-shell and gitlab-test
  def clean_test_path
    Dir[File.join(TMP_TEST_PATH, '**')].each do |entry|
      unless test_dirs.include?(File.basename(entry))
        FileUtils.rm_rf(entry)
      end
    end

    FileUtils.mkdir_p(
      Gitlab::GitalyClient::StorageSettings.allow_disk_access { TestEnv.repos_path }
    )
    FileUtils.mkdir_p(SECOND_STORAGE_PATH)
    FileUtils.mkdir_p(backup_path)
    FileUtils.mkdir_p(pages_path)
    FileUtils.mkdir_p(artifacts_path)
  end

  def setup_gitlab_shell
    FileUtils.mkdir_p(Gitlab.config.gitlab_shell.path)
  end

  def setup_gitaly
    component_timed_setup('Gitaly',
      install_dir: gitaly_dir,
      version: Gitlab::GitalyClient.expected_server_version,
      task: "gitlab:gitaly:install",
      task_args: [gitaly_dir, repos_path, gitaly_url].compact) do
        Gitlab::SetupHelper::Gitaly.create_configuration(
          gitaly_dir,
          { 'default' => repos_path },
          force: true,
          options: {
            prometheus_listen_addr: 'localhost:9236'
          }
        )
        Gitlab::SetupHelper::Gitaly.create_configuration(
          gitaly_dir,
          { 'default' => repos_path },
          force: true,
          options: {
            internal_socket_dir: File.join(gitaly_dir, "internal_gitaly2"),
            gitaly_socket: "gitaly2.socket",
            config_filename: "gitaly2.config.toml"
          }
        )
        Gitlab::SetupHelper::Praefect.create_configuration(gitaly_dir, { 'praefect' => repos_path }, force: true)
      end
  end

  def gitaly_socket_path
    Gitlab::GitalyClient.address('default').sub(/\Aunix:/, '')
  end

  def gitaly_dir
    socket_path = gitaly_socket_path
    socket_path = File.expand_path(gitaly_socket_path) if expand_path?

    File.dirname(socket_path)
  end

  # Linux fails with "bind: invalid argument" if a UNIX socket path exceeds 108 characters:
  # https://github.com/golang/go/issues/6895. We use absolute paths in CI to ensure
  # that changes in the current working directory don't affect GRPC reconnections.
  def expand_path?
    !!ENV['CI']
  end

  def start_gitaly(gitaly_dir)
    if ci?
      # Gitaly has been spawned outside this process already
      return
    end

    spawn_script = Rails.root.join('scripts/gitaly-test-spawn').to_s
    Bundler.with_original_env do
      unless system(spawn_script)
        message = 'gitaly spawn failed'
        message += " (try `rm -rf #{gitaly_dir}` ?)" unless ci?
        raise message
      end
    end

    gitaly_pid = Integer(File.read(TMP_TEST_PATH.join('gitaly.pid')))
    gitaly2_pid = Integer(File.read(TMP_TEST_PATH.join('gitaly2.pid')))
    praefect_pid = Integer(File.read(TMP_TEST_PATH.join('praefect.pid')))

    Kernel.at_exit do
      pids = [gitaly_pid, gitaly2_pid, praefect_pid]
      pids.each { |pid| stop(pid) }
    end

    wait('gitaly')
    wait('praefect')
  end

  def stop(pid)
    Process.kill('KILL', pid)
  rescue Errno::ESRCH
    # The process can already be gone if the test run was INTerrupted.
  end

  def gitaly_url
    ENV.fetch('GITALY_REPO_URL', nil)
  end

  def socket_path(service)
    TMP_TEST_PATH.join('gitaly', "#{service}.socket").to_s
  end

  def praefect_socket_path
    "unix:" + socket_path(:praefect)
  end

  def wait(service)
    sleep_time = 10
    sleep_interval = 0.1
    socket = socket_path(service)

    Integer(sleep_time / sleep_interval).times do
      Socket.unix(socket)
      return
    rescue StandardError
      sleep sleep_interval
    end

    raise "could not connect to #{service} at #{socket.inspect} after #{sleep_time} seconds"
  end

  # Feature specs are run through Workhorse
  def setup_workhorse
    start = Time.now
    return if skip_compile_workhorse?

    FileUtils.rm_rf(workhorse_dir)
    Gitlab::SetupHelper::Workhorse.compile_into(workhorse_dir)
    Gitlab::SetupHelper::Workhorse.create_configuration(workhorse_dir, nil)

    File.write(workhorse_tree_file, workhorse_tree) if workhorse_source_clean?

    puts "==> GitLab Workhorse set up in #{Time.now - start} seconds...\n"
  end

  def skip_compile_workhorse?
    File.directory?(workhorse_dir) &&
      workhorse_source_clean? &&
      File.exist?(workhorse_tree_file) &&
      workhorse_tree == File.read(workhorse_tree_file)
  end

  def workhorse_source_clean?
    out = IO.popen(%w[git status --porcelain workhorse], &:read)
    $?.success? && out.empty?
  end

  def workhorse_tree
    IO.popen(%w[git rev-parse HEAD:workhorse], &:read)
  end

  def workhorse_tree_file
    File.join(workhorse_dir, 'WORKHORSE_TREE')
  end

  def workhorse_dir
    @workhorse_path ||= File.join('tmp', 'tests', 'gitlab-workhorse')
  end

  def with_workhorse(host, port, upstream, &blk)
    host = "[#{host}]" if host.include?(':')
    listen_addr = [host, port].join(':')

    config_path = Gitlab::SetupHelper::Workhorse.get_config_path(workhorse_dir, {})

    # This should be set up in setup_workhorse, but since
    # component_needs_update? only checks that versions are consistent,
    # we need to ensure the config file exists. This line can be removed
    # later after a new Workhorse version is updated.
    Gitlab::SetupHelper::Workhorse.create_configuration(workhorse_dir, nil) unless File.exist?(config_path)

    workhorse_pid = spawn(
      { 'PATH' => "#{ENV['PATH']}:#{workhorse_dir}" },
      File.join(workhorse_dir, 'gitlab-workhorse'),
      '-authSocket', upstream,
      '-documentRoot', Rails.root.join('public').to_s,
      '-listenAddr', listen_addr,
      '-secretPath', Gitlab::Workhorse.secret_path.to_s,
      '-config', config_path,
      '-logFile', 'log/workhorse-test.log',
      '-logFormat', 'structured',
      '-developmentMode' # to serve assets and rich error messages
    )

    begin
      yield
    ensure
      Process.kill('TERM', workhorse_pid)
      Process.wait(workhorse_pid)
    end
  end

  def workhorse_url
    ENV.fetch('GITLAB_WORKHORSE_URL', nil)
  end

  # Create repository for FactoryBot.create(:project)
  def setup_factory_repo
    setup_repo(factory_repo_path, factory_repo_path_bare, factory_repo_name, BRANCH_SHA)
  end

  # Create repository for FactoryBot.create(:forked_project_with_submodules)
  # This repo has a submodule commit that is not present in the main test
  # repository.
  def setup_forked_repo
    setup_repo(forked_repo_path, forked_repo_path_bare, forked_repo_name, FORKED_BRANCH_SHA)
  end

  def setup_repo(repo_path, repo_path_bare, repo_name, refs)
    clone_url = "https://gitlab.com/gitlab-org/#{repo_name}.git"

    unless File.directory?(repo_path)
      start = Time.now
      system(*%W(#{Gitlab.config.git.bin_path} clone --quiet -- #{clone_url} #{repo_path}))
      puts "==> #{repo_path} set up in #{Time.now - start} seconds...\n"
    end

    set_repo_refs(repo_path, refs)

    unless File.directory?(repo_path_bare)
      start = Time.now
      # We must copy bare repositories because we will push to them.
      system(git_env, *%W(#{Gitlab.config.git.bin_path} clone --quiet --bare -- #{repo_path} #{repo_path_bare}))
      puts "==> #{repo_path_bare} set up in #{Time.now - start} seconds...\n"
    end
  end

  def copy_repo(subject, bare_repo:, refs:)
    target_repo_path = File.expand_path(repos_path + "/#{subject.disk_path}.git")

    FileUtils.mkdir_p(target_repo_path)
    FileUtils.cp_r("#{File.expand_path(bare_repo)}/.", target_repo_path)
    FileUtils.chmod_R 0755, target_repo_path
  end

  def rm_storage_dir(storage, dir)
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      repos_path = Gitlab.config.repositories.storages[storage].legacy_disk_path
      target_repo_refs_path = File.join(repos_path, dir)
      FileUtils.remove_dir(target_repo_refs_path)
    end
  rescue Errno::ENOENT
  end

  def storage_dir_exists?(storage, dir)
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      repos_path = Gitlab.config.repositories.storages[storage].legacy_disk_path
      File.exist?(File.join(repos_path, dir))
    end
  end

  def create_bare_repository(path)
    FileUtils.mkdir_p(path)

    system(git_env, *%W(#{Gitlab.config.git.bin_path} -C #{path} init --bare),
           out: '/dev/null',
           err: '/dev/null')
  end

  def repos_path
    @repos_path ||= Gitlab.config.repositories.storages[REPOS_STORAGE].legacy_disk_path
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

  def current_example_group
    Thread.current[:current_example_group]
  end

  # looking for a top-level `describe`
  def topmost_example_group
    example_group = current_example_group
    example_group = example_group[:parent_example_group] until example_group[:parent_example_group].nil?
    example_group
  end

  private

  # These are directories that should be preserved at cleanup time
  def test_dirs
    @test_dirs ||= %w[
      frontend
      gitaly
      gitlab-shell
      gitlab-test
      gitlab-test_bare
      gitlab-test-fork
      gitlab-test-fork_bare
      gitlab-workhorse
      gitlab_workhorse_secret
    ]
  end

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
      raise "Could not update test seed repository, please delete #{repo_path} and try again" unless reset.call
    end
  end

  def component_timed_setup(component, install_dir:, version:, task:, task_args: [])
    start = Time.now

    ensure_component_dir_name_is_correct!(component, install_dir)

    # On CI, once installed, components never need update
    return if File.exist?(install_dir) && ci?

    if component_needs_update?(install_dir, version)
      # Cleanup the component entirely to ensure we start fresh
      FileUtils.rm_rf(install_dir)

      if ENV['SKIP_RAILS_ENV_IN_RAKE']
        # When we run `scripts/setup-test-env`, we take care of loading the necessary dependencies
        # so we can run the rake task programmatically.
        Rake::Task[task].invoke(*task_args)
      else
        # In other cases, we run the task via `rake` so that the environment
        # and dependencies are automatically loaded.
        raise ComponentFailedToInstallError unless system('rake', "#{task}[#{task_args.join(',')}]")
      end

      yield if block_given?

      puts "==> #{component} set up in #{Time.now - start} seconds...\n"
    end
  rescue ComponentFailedToInstallError
    puts "\n#{component} failed to install, cleaning up #{install_dir}!\n"
    FileUtils.rm_rf(install_dir)
    exit 1
  end

  def ci?
    ENV['CI'].present?
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

    return false if component_matches_git_sha?(component_folder, expected_version)

    return false if component_ahead_of_target?(component_folder, expected_version)

    version = File.read(File.join(component_folder, 'VERSION')).strip

    # Notice that this will always yield true when using branch versions
    # (`=branch_name`), but that actually makes sure the server is always based
    # on the latest branch revision.
    version != expected_version
  rescue Errno::ENOENT
    true
  end

  def component_ahead_of_target?(component_folder, expected_version)
    # The HEAD of the component_folder will be used as heuristic for the version
    # of the binaries, allowing to use Git to determine if HEAD is later than
    # the expected version. Note: Git considers HEAD to be an anchestor of HEAD.
    _out, exit_status = Gitlab::Popen.popen(%W[
      #{Gitlab.config.git.bin_path}
      -C #{component_folder}
      merge-base --is-ancestor
      #{expected_version} HEAD
])

    exit_status == 0
  end

  def component_matches_git_sha?(component_folder, expected_version)
    # Not a git SHA, so return early
    return false unless expected_version =~ ::Gitlab::Git::COMMIT_ID

    sha, exit_status = Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} rev-parse HEAD), component_folder)
    return false if exit_status != 0

    expected_version == sha.chomp
  end
end

require_relative('../../../ee/spec/support/helpers/ee/test_env') if Gitlab.ee?

::TestEnv.prepend_mod_with('TestEnv')
::TestEnv.extend_mod_with('TestEnv')

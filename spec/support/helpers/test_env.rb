# frozen_string_literal: true

require 'parallel'
require_relative 'gitaly_setup'
require_relative '../../../lib/gitlab/setup_helper'

module TestEnv
  extend self

  def self.included(_)
    raise "Don't include TestEnv. Use TestEnv.<method> instead."
  end

  ComponentFailedToInstallError = Class.new(StandardError)

  # https://gitlab.com/gitlab-org/gitlab-test is used to seed your local gdk
  # GitLab application and is also used in rspec tests.  Because of this, when
  # building and testing features that require a specific type of file, you can
  # add them to the gitlab-test repo in order to access that blob during
  # development or testing.
  #
  # To add new branches
  #
  # 1. Push a new branch to gitlab-org/gitlab-test.
  # 2. Execute rm -rf tmp/tests in your gitlab repo.
  # 3. Add your branch and its HEAD commit sha to the BRANCH_SHA hash
  # 4. Increment expected number of commits for context
  #    "returns the number of commits in the whole repository" in spec/lib/gitlab/git/repository_spec.rb
  #
  # To add new commits to an existing branch
  #
  # 1. Push a new commit to a branch in gitlab-org/gitlab-test.
  # 2. Execute rm -rf tmp/tests in your gitlab repo.
  # 3. Update the HEAD sha value in the BRANCH_SHA hash
  # 4. Increment expected number of commits for context
  #    "returns the number of commits in the whole repository" in spec/lib/gitlab/git/repository_spec.rb
  #
  BRANCH_SHA = {
    'signed-commits' => 'c7794c1',
    'gpg-signed' => '8a852d5',
    'x509-signed' => 'a4df3c8',
    'not-merged-branch' => 'b83d6e3',
    'branch-merged' => '498214d',
    'empty-branch' => '7efb185',
    'ends-with.json' => '98b0d8b',
    'flatten-dir' => 'e56497b',
    'feature' => '0b4bc9a',
    'feature_conflict' => 'bb5206f',
    'fix' => '48f0be4',
    'improve/awesome' => '5937ac0',
    'merged-target' => '21751bf',
    'markdown' => '0ed8c6c',
    'lfs' => '55bc176',
    'master' => 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
    'merge-test' => '5937ac0',
    "'test'" => 'e56497b',
    'orphaned-branch' => '45127a9',
    'binary-encoding' => '7b1cf43',
    'gitattributes' => '5a62481',
    'expand-collapse-diffs' => '4842455',
    'symlink-expand-diff' => '81e6355',
    'diff-files-symlink-to-image' => '8cfca84',
    'diff-files-image-to-symlink' => '3e94fda',
    'diff-files-symlink-to-text' => '689815e',
    'diff-files-text-to-symlink' => '5e2c270',
    'expand-collapse-files' => '025db92',
    'expand-collapse-lines' => '238e82d',
    'pages-deploy' => '7897d5b',
    'pages-deploy-target' => '7975be0',
    'audio' => 'c3c21fd',
    'video' => '8879059',
    'crlf-diff' => '5938907',
    'conflict-start' => '824be60',
    'conflict-resolvable' => '1450cd639e0bc6721eb02800169e464f212cde06',
    'conflict-binary-file' => '259a6fb',
    'conflict-contains-conflict-markers' => '78a3086',
    'conflict-missing-side' => 'eb227b3',
    'conflict-non-utf8' => 'd0a293c',
    'conflict-too-large' => '39fa04f',
    'deleted-image-test' => '6c17798',
    'wip' => 'b9238ee',
    'csv' => '3dd0896',
    'v1.1.0' => 'b83d6e3',
    'add-ipython-files' => '4963fef',
    'add-pdf-file' => 'e774ebd',
    'squash-large-files' => '54cec52',
    'add-pdf-text-binary' => '79faa7b',
    'add_images_and_changes' => '010d106',
    'update-gitlab-shell-v-6-0-1' => '2f61d70',
    'update-gitlab-shell-v-6-0-3' => 'de78448',
    'merge-commit-analyze-before' => '1adbdef',
    'merge-commit-analyze-side-branch' => '8a99451',
    'merge-commit-analyze-after' => '646ece5',
    'snippet/single-file' => '43e4080aaa14fc7d4b77ee1f5c9d067d5a7df10e',
    'snippet/multiple-files' => '40232f7eb98b3f221886432def6e8bab2432add9',
    'snippet/rename-and-edit-file' => '220a1e4b4dff37feea0625a7947a4c60fbe78365',
    'snippet/edit-file' => 'c2f074f4f26929c92795a75775af79a6ed6d8430',
    'snippet/no-files' => '671aaa842a4875e5f30082d1ab6feda345fdb94d',
    '2-mb-file' => 'bf12d25',
    'before-create-delete-modify-move' => '845009f',
    'between-create-delete-modify-move' => '3f5f443',
    'after-create-delete-modify-move' => 'ba3faa7',
    'with-codeowners' => '219560e',
    'submodule_inside_folder' => 'b491b92',
    'png-lfs' => 'fe42f41',
    'sha-starting-with-large-number' => '8426165',
    'invalid-utf8-diff-paths' => '99e4853',
    'compare-with-merge-head-source' => 'f20a03d',
    'compare-with-merge-head-target' => '2f1e176',
    'trailers' => 'f0a5ed6',
    'add_commit_with_5mb_subject' => '8cf8e80',
    'blame-on-renamed' => '32c33da',
    'with-executables' => '6b8dc4a',
    'spooky-stuff' => 'ba3343b',
    'few-commits' => '0031876',
    'two-commits' => '304d257',
    'utf-16' => 'f05a987',
    'gitaly-rename-test' => '94bb47c',
    'smime-signed-commits' => 'ed775cc',
    'Ääh-test-utf-8' => '7975be0',
    'ssh-signed-commit' => '7b5160f',
    'changes-with-whitespace' => 'f2d141fadb33ceaafc95667c1a0a308ad5edc5f9',
    'changes-with-only-whitespace' => '80cffbb2ad86202171dd3c05b38b5b4523b447d3',
    'lock-detection' => '1ada92f78a19f27cb442a0a205f1c451a3a15432',
    'expanded-whitespace-target' => '279aa723d4688e711652d230c93f1fc33801dcb8',
    'expanded-whitespace-source' => 'e6f8b802fe2288b1b5e367c5dde736594971ebd1',
    'submodule-with-dot' => 'b4a4435df7e7605dd9930d0c5402087b37da99bf'
  }.freeze

  # gitlab-test-fork is a fork of gitlab-fork, but we don't necessarily
  # need to keep all the branches in sync.
  # We currently only need a subset of the branches
  FORKED_BRANCH_SHA = {
    'add-submodule-version-bump' => '3f547c0',
    'master' => '5937ac0',
    'remove-submodule' => '2a33e0c',
    'conflict-resolvable-fork' => '404fa3f'
  }.freeze

  TMP_TEST_PATH = Rails.root.join('tmp', 'tests').freeze
  SETUP_METHODS = %i[setup_go_projects setup_factory_repo setup_forked_repo].freeze

  # Can be overriden
  def setup_methods
    SETUP_METHODS
  end

  # Can be overriden
  # The Go build cache is not safe for concurrent builds:
  # https://github.com/golang/go/issues/43645
  def setup_go_projects
    setup_gitaly
    setup_gitlab_shell
    setup_workhorse
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
    start_gitaly
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

    FileUtils.mkdir_p(backup_path)
    FileUtils.mkdir_p(pages_path)
    FileUtils.mkdir_p(artifacts_path)
    FileUtils.mkdir_p(lfs_path)
    FileUtils.mkdir_p(terraform_state_path)
    FileUtils.mkdir_p(packages_path)
    FileUtils.mkdir_p(ci_secure_files_path)
    FileUtils.mkdir_p(external_diffs_path)
  end

  def setup_gitlab_shell
    FileUtils.mkdir_p(Gitlab.config.gitlab_shell.path)
  end

  def setup_gitaly
    component_timed_setup('Gitaly',
      install_dir: GitalySetup.gitaly_dir,
      version: Gitlab::GitalyClient.expected_server_version,
      task: "gitlab:gitaly:clone",
      fresh_install: ENV.key?('FORCE_GITALY_INSTALL'),
      task_args: [GitalySetup.gitaly_dir, GitalySetup.storage_path, gitaly_url].compact) do
      GitalySetup.setup_gitaly
    end
  end

  def start_gitaly
    if ci?
      # Gitaly has been spawned outside this process already
      return
    end

    GitalySetup.spawn_gitaly
  end

  def gitaly_url
    ENV.fetch('GITALY_REPO_URL', nil)
  end

  # Feature specs are run through Workhorse
  def setup_workhorse
    # Always rebuild the config file
    if skip_compile_workhorse?
      Gitlab::SetupHelper::Workhorse.create_configuration(workhorse_dir, nil, force: true)
      return
    end

    start = Time.now

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
    @workhorse_path ||= Rails.root.join('tmp', 'tests', 'gitlab-workhorse')
  end

  def with_workhorse(host, port, upstream, &blk)
    host = "[#{host}]" if host.include?(':')
    listen_addr = [host, port].join(':')

    config_path = Gitlab::SetupHelper::Workhorse.get_config_path(workhorse_dir, {})

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
    setup_repo(factory_repo_path, factory_repo_bundle_path, factory_repo_name, BRANCH_SHA)
  end

  # Create repository for FactoryBot.create(:forked_project_with_submodules)
  # This repo has a submodule commit that is not present in the main test
  # repository.
  def setup_forked_repo
    setup_repo(forked_repo_path, forked_repo_bundle_path, forked_repo_name, FORKED_BRANCH_SHA)
  end

  def setup_repo(repo_path, repo_bundle_path, repo_name, refs)
    clone_url = "https://gitlab.com/gitlab-org/#{repo_name}.git"

    unless File.directory?(repo_path)
      start = Time.now
      system(*%W[#{Gitlab.config.git.bin_path} clone --quiet -- #{clone_url} #{repo_path}])
      puts "==> #{repo_path} set up in #{Time.now - start} seconds...\n"
    end

    create_bundle = !File.file?(repo_bundle_path)

    unless set_repo_refs(repo_path, refs)
      # Prefer not to fetch over the network. Only fetch when we have failed to
      # set all the required local branches. This would happen when a new
      # branch is added to BRANCH_SHA, in which case we want to update
      # everything.
      unless system(*%W[#{Gitlab.config.git.bin_path} -C #{repo_path} fetch origin])
        raise 'Could not fetch test seed repository.'
      end

      unless set_repo_refs(repo_path, refs)
        raise "Could not update test seed repository, please delete #{repo_path} and try again"
      end

      create_bundle = true
    end

    if create_bundle
      start = Time.now
      system(git_env, *%W[#{Gitlab.config.git.bin_path} -C #{repo_path} bundle create #{repo_bundle_path} --exclude refs/remotes/* --all])
      puts "==> #{repo_bundle_path} generated in #{Time.now - start} seconds...\n"
    end
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

  def lfs_path
    Gitlab.config.lfs.storage_path
  end

  def terraform_state_path
    Gitlab.config.terraform_state.storage_path
  end

  def packages_path
    Gitlab.config.packages.storage_path
  end

  def ci_secure_files_path
    Gitlab.config.ci_secure_files.storage_path
  end

  def external_diffs_path
    Gitlab.config.external_diffs.storage_path
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

  def factory_repo_path
    @factory_repo_path ||= Rails.root.join('tmp', 'tests', factory_repo_name)
  end

  def forked_repo_path
    @forked_repo_path ||= Rails.root.join('tmp', 'tests', forked_repo_name)
  end

  def factory_repo_bundle_path
    "#{factory_repo_path}.bundle"
  end

  def forked_repo_bundle_path
    "#{forked_repo_path}.bundle"
  end

  def seed_db
    # Adjust `deletion_except_tables` method to exclude seeded tables from
    # record deletions.
    Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
    Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter.upsert_restrictions
    Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter.upsert_restrictions

    # Updating old_id to simulate an environment that has gone through the process of cleaning
    # the issues.work_item_type_id column. old_id is used as a fallback id.
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/499911
    WorkItems::Type.find_each do |work_item_type|
      work_item_type.update!(old_id: -work_item_type.id)
    end
  end

  private

  # These are directories that should be preserved at cleanup time
  def test_dirs
    @test_dirs ||= [
      'frontend',
      'gitaly',
      'gitlab-shell',
      'gitlab-test',
      'gitlab-test.bundle',
      'gitlab-test-fork',
      'gitlab-test-fork.bundle',
      'gitlab-workhorse',
      'gitlab_workhorse_secret',
      File.basename(GitalySetup.storage_path),
      File.basename(GitalySetup.second_storage_path)
    ]
  end

  def factory_repo_name
    'gitlab-test'
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
    IO.popen(%W[#{Gitlab.config.git.bin_path} -C #{repo_path} update-ref --stdin -z], "w") do |io|
      branch_sha.each do |branch, sha|
        io.write("update refs/heads/#{branch}\x00#{sha}\x00\x00")
      end
    end

    $?.success?
  end

  def component_timed_setup(component, install_dir:, version:, task:, fresh_install: true, task_args: [])
    start = Time.now

    ensure_component_dir_name_is_correct!(component, install_dir)

    # On CI, once installed, components never need update
    return if File.exist?(install_dir) && ci?

    if component_needs_update?(install_dir, version)
      puts "==> Starting #{component} (#{version}) set up...\n"

      # Cleanup the component entirely to ensure we start fresh
      FileUtils.rm_rf(install_dir) if fresh_install

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
    return false unless Dir.exist?(File.join(component_folder, '.git'))

    # The HEAD of the component_folder will be used as heuristic for the version
    # of the binaries, allowing to use Git to determine if HEAD is later than
    # the expected version. Note: Git considers HEAD to be an anchestor of HEAD.
    _out, exit_status = Gitlab::Popen.popen(
      %W[
        #{Gitlab.config.git.bin_path}
        -C #{component_folder}
        merge-base --is-ancestor
        #{expected_version} HEAD
      ]
    )

    exit_status == 0
  end

  def component_matches_git_sha?(component_folder, expected_version)
    # Not a git SHA, so return early
    return false unless ::Gitlab::Git::COMMIT_ID.match?(expected_version)

    return false unless Dir.exist?(component_folder)

    return false unless Dir.exist?(File.join(component_folder, '.git'))

    sha, exit_status = Gitlab::Popen.popen(%W[#{Gitlab.config.git.bin_path} rev-parse HEAD], component_folder)
    return false if exit_status != 0

    expected_version == sha.chomp
  end
end

require_relative('../../../ee/spec/support/helpers/ee/test_env') if Gitlab.ee?

::TestEnv.prepend_mod_with('TestEnv')
::TestEnv.extend_mod_with('TestEnv')

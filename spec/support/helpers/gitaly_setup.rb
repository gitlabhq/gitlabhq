# frozen_string_literal: true

# This file contains environment settings for gitaly when it's running
# as part of the gitlab-ce/ee test suite.
#
# Please be careful when modifying this file. Your changes must work
# both for local development rspec runs, and in CI.

require 'securerandom'
require 'socket'
require 'logger'
require 'fileutils'
require 'gitlab/utils/all'

module GitalySetup
  extend self

  REPOS_STORAGE = 'default'

  LOGGER = begin
    default_name = ENV['CI'] ? 'DEBUG' : 'WARN'
    level_name = ENV['GITLAB_TESTING_LOG_LEVEL']&.upcase
    level = Logger.const_get(level_name || default_name, true) # rubocop: disable Gitlab/ConstGetInheritFalse
    Logger.new($stdout, level: level, formatter: ->(_, _, _, msg) { msg })
  end

  # Expands a path relative to rails root. This module is used in non-rails
  # contexts and so Rails.root cannot be used.
  def expand_path(path)
    File.expand_path(path, File.join(__dir__, '../../..'))
  end

  def storage_path
    expand_path('tmp/tests/repositories')
  end

  def second_storage_path
    expand_path('tmp/tests/second_storage')
  end

  def tmp_tests_gitaly_dir
    expand_path('tmp/tests/gitaly')
  end

  def runtime_dir
    expand_path('tmp/run')
  end

  def tmp_tests_gitaly_bin_dir
    File.join(tmp_tests_gitaly_dir, '_build', 'bin')
  end

  def tmp_tests_gitlab_shell_dir
    expand_path('tmp/tests/gitlab-shell')
  end

  def rails_gitlab_shell_secret
    expand_path('.gitlab_shell_secret')
  end

  def gitlab_shell_secret_file
    File.join(tmp_tests_gitlab_shell_dir, '.gitlab_shell_secret')
  end

  def env
    {
      # Git hooks can't run during tests as the internal API is not running.
      'GITALY_TESTING_NO_GIT_HOOKS' => "1",
      'GITALY_TESTING_ENABLE_ALL_FEATURE_FLAGS' => "true"
    }
  end

  def config_name(service)
    case service
    when :gitaly
      'config.toml'
    when :gitaly2
      'gitaly2.config.toml'
    when :praefect
      'praefect.config.toml'
    end
  end

  def config_path(service)
    File.join(tmp_tests_gitaly_dir, config_name(service))
  end

  def service_cmd(service, toml = nil)
    toml ||= config_path(service)

    case service
    when :gitaly, :gitaly2
      [File.join(tmp_tests_gitaly_bin_dir, 'gitaly'), toml]
    when :praefect
      [File.join(tmp_tests_gitaly_bin_dir, 'praefect'), '-config', toml]
    end
  end

  def run_command(cmd, env: {})
    system(env, *cmd, exception: true, chdir: tmp_tests_gitaly_dir)
  end

  def build_gitaly
    run_command(%w[make all WITH_BUNDLED_GIT=YesPlease], env: env.merge('GIT_VERSION' => nil))
  end

  def start_gitaly(service, toml = nil)
    case service
    when :gitaly
      FileUtils.mkdir_p(GitalySetup.storage_path)
    when :gitaly2
      FileUtils.mkdir_p(GitalySetup.second_storage_path)
    end

    if gitaly_with_transactions? && !toml
      # The configuration file with transactions is pre-generated. Here we check
      # whether this job should actually run with transactions and choose the pre-generated
      # configuration with transactions enabled if so.
      #
      # Workhorse provides its own configuration through 'toml'. If a configuration is
      # explicitly provided, we don't override it. Workhorse test setup has its own logic
      # to choose the configuration with transactions enabled.
      toml = "#{config_path(service)}.transactions"
    end

    start(service, toml)
  end

  def start_praefect
    if praefect_with_db?
      LOGGER.debug 'Starting Praefect with database election strategy'
      start(:praefect, File.join(tmp_tests_gitaly_dir, 'praefect-db.config.toml'))
    else
      LOGGER.debug 'Starting Praefect with in-memory election strategy'
      start(:praefect)
    end
  end

  def start(service, toml = nil)
    toml ||= config_path(service)
    args = service_cmd(service, toml)

    # Ensure that tmp/run exists
    FileUtils.mkdir_p(runtime_dir)

    # Ensure user configuration does not affect Git
    # Context: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58776#note_547613780
    env = self.env.merge('HOME' => nil, 'XDG_CONFIG_HOME' => nil)

    pid = spawn(env, *args, [:out, :err] => "log/#{service}-test.log")

    begin
      try_connect!(service, toml)
    rescue StandardError
      process_details(pid)
      Process.kill('TERM', pid)
      raise
    end

    pid
  end

  # Taken from Gitlab::Shell.generate_and_link_secret_token
  def ensure_gitlab_shell_secret!
    secret_file = rails_gitlab_shell_secret
    shell_link = gitlab_shell_secret_file

    unless File.size?(secret_file)
      File.write(secret_file, SecureRandom.hex(16))
    end

    unless File.exist?(shell_link)
      FileUtils.ln_s(secret_file, shell_link)
    end
  end

  def connect_proc(toml)
    # This code needs to work in an environment where we cannot use bundler,
    # so we cannot easily use the toml-rb gem. This ad-hoc parser should be
    # good enough.
    config_text = File.read(toml)

    config_text.lines.each do |line|
      match_data = line.match(/^\s*(socket_path|listen_addr)\s*=\s*"([^"]*)"$/)

      next unless match_data

      case match_data[1]
      when 'socket_path'
        return -> { UNIXSocket.new(match_data[2]) }
      when 'listen_addr'
        addr, port = match_data[2].split(':')
        return -> { TCPSocket.new(addr, port.to_i) }
      end
    end

    raise "failed to find socket_path or listen_addr in #{toml}"
  end

  def try_connect!(service, toml)
    LOGGER.debug "Trying to connect to #{service}: "
    timeout = 40
    delay = 0.1
    connect = connect_proc(toml)

    Integer(timeout / delay).times do
      connect.call
      LOGGER.debug " OK\n"

      return
    rescue Errno::ENOENT, Errno::ECONNREFUSED
      LOGGER.debug '.'
      sleep delay
    end

    LOGGER.warn " FAILED to connect to #{service}\n"

    raise "could not connect to #{service}"
  end

  def gitaly_socket_path
    Gitlab::GitalyClient.address(REPOS_STORAGE).delete_prefix('unix:')
  end

  # Extracts the gitaly install directory based on the gitaly socket configured
  # in gitlab.yml. This allows the test gitaly to be temporarily overridden.
  def gitaly_dir
    socket_path = gitaly_socket_path
    socket_path = File.expand_path(gitaly_socket_path) if expand_path_for_socket?

    File.dirname(socket_path)
  end

  # Linux fails with "bind: invalid argument" if a UNIX socket path exceeds 108 characters:
  # https://github.com/golang/go/issues/6895. We use absolute paths in CI to ensure
  # that changes in the current working directory don't affect GRPC reconnections.
  def expand_path_for_socket?
    !!ENV['CI']
  end

  def setup_gitaly
    unless ENV['CI']
      # In CI Gitaly is built in the setup-test-env job and saved in the
      # artifacts. So when tests are started, there's no need to build Gitaly.
      build_gitaly
    end

    [
      {
        storages: { 'default' => storage_path },
        options: {
          runtime_dir: runtime_dir,
          prometheus_listen_addr: 'localhost:9236',
          config_filename: config_name(:gitaly),
          transactions_enabled: false
        }
      },
      {
        storages: { 'test_second_storage' => second_storage_path },
        options: {
          runtime_dir: runtime_dir,
          gitaly_socket: "gitaly2.socket",
          config_filename: config_name(:gitaly2),
          transactions_enabled: false
        }
      }
    ].each do |params|
      Gitlab::SetupHelper::Gitaly.create_configuration(
        gitaly_dir,
        params[:storages],
        force: true,
        options: params[:options]
      )

      # CI generates all of the configuration files in the setup-test-env job. When we eventually get
      # to run the rspec jobs with transactions enabled, the configuration has already been created
      # without transactions enabled.
      #
      # Similarly to the Praefect configuration, generate variant of the configuration file with
      # transactions enabled. Later when the rspec job runs, we decide whether to run Gitaly
      # using the configuration with transactions enabled or not.
      #
      # These configuration files are only used in the CI.
      params[:options][:config_filename] = "#{params[:options][:config_filename]}.transactions"
      params[:options][:transactions_enabled] = true

      Gitlab::SetupHelper::Gitaly.create_configuration(
        gitaly_dir,
        params[:storages],
        force: true,
        options: params[:options]
      )
    end

    # In CI we need to pre-generate both config files.
    # For local testing we'll create the correct file on-demand.
    if ENV['CI'] || !praefect_with_db?
      Gitlab::SetupHelper::Praefect.create_configuration(
        gitaly_dir,
        nil,
        force: true
      )
    end

    if ENV['CI'] || praefect_with_db?
      Gitlab::SetupHelper::Praefect.create_configuration(
        gitaly_dir,
        nil,
        force: true,
        options: {
          per_repository: true,
          config_filename: 'praefect-db.config.toml',
          pghost: ENV['CI'] ? 'postgres' : ENV.fetch('PGHOST'),
          pgport: ENV['CI'] ? 5432 : ENV.fetch('PGPORT').to_i,
          pguser: ENV['CI'] ? 'postgres' : ENV.fetch('USER')
        }
      )
    end

    # In CI no database is running when Gitaly is set up
    # so scripts/gitaly-test-spawn will take care of it instead.
    setup_praefect unless ENV['CI']
  end

  def setup_praefect
    return unless praefect_with_db?

    migrate_cmd = service_cmd(:praefect, File.join(tmp_tests_gitaly_dir, 'praefect-db.config.toml')) + ['sql-migrate']
    system(env, *migrate_cmd, [:out, :err] => 'log/praefect-test.log')
  end

  def socket_path(service)
    File.join(tmp_tests_gitaly_dir, "#{service}.socket")
  end

  def praefect_socket_path
    "unix:" + socket_path(:praefect)
  end

  def stop(pid)
    Process.kill('KILL', pid)
  rescue Errno::ESRCH
    # The process can already be gone if the test run was INTerrupted.
  end

  def spawn_gitaly(toml = nil)
    pids = []

    if toml
      pids << start_gitaly(:gitaly, toml)
    else
      pids << start_gitaly(:gitaly)
      pids << start_gitaly(:gitaly2)
      pids << start_praefect
    end

    Kernel.at_exit do
      # In CI, this function is called by scripts/gitaly-test-spawn, triggered
      # in a before_script. Gitaly needs to remain running until the container
      # is stopped.
      next if ENV['CI']
      # In Workhorse tests (locally or in CI), this function is called by
      # scripts/gitaly-test-spawn during `make test`. Gitaly needs to remain
      # running until `make test` cleans it up.
      next if ENV['GITALY_PID_FILE']

      ::Gitlab::GitalyClient.clear_stubs!

      pids.each { |pid| stop(pid) }

      [storage_path, second_storage_path].each { |storage_dir| FileUtils.rm_rf(storage_dir) }
    end
  rescue StandardError
    raise gitaly_failure_message
  end

  def gitaly_failure_message
    message = "gitaly spawn failed\n\n"

    message += "- The `gitaly` binary does not exist: #{gitaly_binary}\n" unless File.exist?(gitaly_binary)
    message += "- The `praefect` binary does not exist: #{praefect_binary}\n" unless File.exist?(praefect_binary)
    message += "- No `git` binaries exist\n" if git_binaries.empty?

    message += read_log_file('log/gitaly-test.log')
    message += read_log_file('log/gitaly2-test.log')
    message += read_log_file('log/praefect-test.log')

    unless ENV['CI']
      message += "\nIf binaries are missing, try running `make -C tmp/tests/gitaly all WITH_BUNDLED_GIT=YesPlease`.\n"
      message += "\nOtherwise, try running `rm -rf #{tmp_tests_gitaly_dir}`."
    end

    message
  end

  def read_log_file(logs_path)
    return '' unless File.exist?(logs_path)

    <<~LOGS
      \n#{logs_path}:\n
      #{File.read(logs_path)}
    LOGS
  end

  def git_binaries
    Dir.glob(File.join(tmp_tests_gitaly_dir, "_build", "bin", "gitaly-git-v*"))
  end

  def gitaly_binary
    File.join(tmp_tests_gitaly_dir, "_build", "bin", "gitaly")
  end

  def praefect_binary
    File.join(tmp_tests_gitaly_dir, "_build", "bin", "praefect")
  end

  def praefect_with_db?
    Gitlab::Utils.to_boolean(ENV['GITALY_PRAEFECT_WITH_DB'], default: false)
  end

  def gitaly_with_transactions?
    Gitlab::Utils.to_boolean(ENV['GITALY_TRANSACTIONS_ENABLED'], default: false)
  end

  private

  # Logs the details of the process with the given pid.
  def process_details(pid)
    output = `ps -p #{pid} -o pid,ppid,state,%cpu,%mem,etime,args`
    LOGGER.debug output
  end
end

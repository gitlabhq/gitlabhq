# frozen_string_literal: true

# This file contains environment settings for gitaly when it's running
# as part of the gitlab-ce/ee test suite.
#
# Please be careful when modifying this file. Your changes must work
# both for local development rspec runs, and in CI.

require 'securerandom'
require 'socket'
require 'logger'
require 'bundler'

module GitalySetup
  extend self

  REPOS_STORAGE = 'default'

  LOGGER = begin
    default_name = ENV['CI'] ? 'DEBUG' : 'WARN'
    level_name = ENV['GITLAB_TESTING_LOG_LEVEL']&.upcase
    level = Logger.const_get(level_name || default_name, true) # rubocop: disable Gitlab/ConstGetInheritFalse
    Logger.new($stdout, level: level, formatter: ->(_, _, _, msg) { msg })
  end

  def expand_path(path)
    File.expand_path(path, File.join(__dir__, '../../..'))
  end

  def tmp_tests_gitaly_dir
    expand_path('tmp/tests/gitaly')
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

  def gemfile
    File.join(tmp_tests_gitaly_dir, 'ruby', 'Gemfile')
  end

  def gemfile_dir
    File.dirname(gemfile)
  end

  def gitlab_shell_secret_file
    File.join(tmp_tests_gitlab_shell_dir, '.gitlab_shell_secret')
  end

  def env
    {
      'GEM_PATH' => Gem.path.join(':'),
      'BUNDLE_INSTALL_FLAGS' => nil,
      'BUNDLE_IGNORE_CONFIG' => '1',
      'BUNDLE_PATH' => bundle_path,
      'BUNDLE_GEMFILE' => gemfile,
      'BUNDLE_JOBS' => '4',
      'BUNDLE_RETRY' => '3',
      'RUBYOPT' => nil,

      # Git hooks can't run during tests as the internal API is not running.
      'GITALY_TESTING_NO_GIT_HOOKS' => "1",
      'GITALY_TESTING_ENABLE_ALL_FEATURE_FLAGS' => "true"
    }
  end

  def bundle_path
    # Allow the user to override BUNDLE_PATH if they need to
    return ENV['GITALY_TEST_BUNDLE_PATH'] if ENV['GITALY_TEST_BUNDLE_PATH']

    if ENV['CI']
      expand_path('vendor/gitaly-ruby')
    else
      explicit_path = Bundler.configured_bundle_path.explicit_path

      return unless explicit_path

      expand_path(explicit_path)
    end
  end

  def config_path(service)
    case service
    when :gitaly
      File.join(tmp_tests_gitaly_dir, 'config.toml')
    when :gitaly2
      File.join(tmp_tests_gitaly_dir, 'gitaly2.config.toml')
    when :praefect
      File.join(tmp_tests_gitaly_dir, 'praefect.config.toml')
    end
  end

  def repos_path(storage = REPOS_STORAGE)
    Gitlab.config.repositories.storages[REPOS_STORAGE].legacy_disk_path
  end

  def service_binary(service)
    case service
    when :gitaly, :gitaly2
      'gitaly'
    when :praefect
      'praefect'
    end
  end

  def run_command(cmd, env: {})
    system(env, *cmd, exception: true, chdir: tmp_tests_gitaly_dir)
  end

  def install_gitaly_gems
    run_command(%W[make #{tmp_tests_gitaly_dir}/.ruby-bundle], env: env)
  end

  def build_gitaly
    run_command(%w[make all WITH_BUNDLED_GIT=YesPlease], env: env.merge('GIT_VERSION' => nil))
  end

  def start_gitaly(toml = nil)
    start(:gitaly, toml)
  end

  def start_gitaly2
    start(:gitaly2)
  end

  def start_praefect
    start(:praefect)
  end

  def start(service, toml = nil)
    toml ||= config_path(service)
    args = ["#{tmp_tests_gitaly_bin_dir}/#{service_binary(service)}"]
    args.push("-config") if service == :praefect
    args.push(toml)

    # Ensure user configuration does not affect Git
    # Context: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58776#note_547613780
    env = self.env.merge('HOME' => nil, 'XDG_CONFIG_HOME' => nil)

    pid = spawn(env, *args, [:out, :err] => "log/#{service}-test.log")

    begin
      try_connect!(service, toml)
    rescue StandardError
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

  def check_gitaly_config!
    LOGGER.debug "Checking gitaly-ruby Gemfile...\n"

    unless File.exist?(gemfile)
      message = "#{gemfile} does not exist."
      message += "\n\nThis might have happened if the CI artifacts for this build were destroyed." if ENV['CI']
      abort message
    end

    LOGGER.debug "Checking gitaly-ruby bundle...\n"
    out = ENV['CI'] ? $stdout : '/dev/null'
    abort 'bundle check failed' unless system(env, 'bundle', 'check', out: out, chdir: gemfile_dir)
  end

  def connect_proc(toml)
    # This code needs to work in an environment where we cannot use bundler,
    # so we cannot easily use the toml-rb gem. This ad-hoc parser should be
    # good enough.
    config_text = IO.read(toml)

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
    timeout = 20
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
    check_gitaly_config!

    pids = []

    if toml
      pids << start_gitaly(toml)
    else
      pids << start_gitaly
      pids << start_gitaly2
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

      pids.each { |pid| stop(pid) }
    end
  rescue StandardError
    raise gitaly_failure_message
  end

  def gitaly_failure_message
    message = "gitaly spawn failed\n\n"

    message += "- The `gitaly` binary does not exist: #{gitaly_binary}\n" unless File.exist?(gitaly_binary)
    message += "- The `praefect` binary does not exist: #{praefect_binary}\n" unless File.exist?(praefect_binary)
    message += "- The `git` binary does not exist: #{git_binary}\n" unless File.exist?(git_binary)

    message += "\nCheck log/gitaly-test.log for errors.\n"

    unless ENV['CI']
      message += "\nIf binaries are missing, try running `make -C tmp/tests/gitaly all WITH_BUNDLED_GIT=YesPlease`.\n"
      message += "\nOtherwise, try running `rm -rf #{tmp_tests_gitaly_dir}`."
    end

    message
  end

  def git_binary
    File.join(tmp_tests_gitaly_dir, "_build", "bin", "gitaly-git")
  end

  def gitaly_binary
    File.join(tmp_tests_gitaly_dir, "_build", "bin", "gitaly")
  end

  def praefect_binary
    File.join(tmp_tests_gitaly_dir, "_build", "bin", "praefect")
  end

  def git_binary_exists?
    File.exist?(git_binary)
  end
end

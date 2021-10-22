# frozen_string_literal: true

# This file contains environment settings for gitaly when it's running
# as part of the gitlab-ce/ee test suite.
#
# Please be careful when modifying this file. Your changes must work
# both for local development rspec runs, and in CI.

require 'securerandom'
require 'socket'
require 'logger'

module GitalySetup
  LOGGER = begin
    default_name = ENV['CI'] ? 'DEBUG' : 'WARN'
    level_name = ENV['GITLAB_TESTING_LOG_LEVEL']&.upcase
    level = Logger.const_get(level_name || default_name, true) # rubocop: disable Gitlab/ConstGetInheritFalse
    Logger.new($stdout, level: level, formatter: ->(_, _, _, msg) { msg })
  end

  def tmp_tests_gitaly_dir
    File.expand_path('../../../tmp/tests/gitaly', __dir__)
  end

  def tmp_tests_gitaly_bin_dir
    File.join(tmp_tests_gitaly_dir, '_build', 'bin')
  end

  def tmp_tests_gitlab_shell_dir
    File.expand_path('../../../tmp/tests/gitlab-shell', __dir__)
  end

  def rails_gitlab_shell_secret
    File.expand_path('../../../.gitlab_shell_secret', __dir__)
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
      'HOME' => File.expand_path('tmp/tests'),
      'GEM_PATH' => Gem.path.join(':'),
      'BUNDLE_APP_CONFIG' => File.join(gemfile_dir, '.bundle'),
      'BUNDLE_INSTALL_FLAGS' => nil,
      'BUNDLE_GEMFILE' => gemfile,
      'RUBYOPT' => nil,

      # Git hooks can't run during tests as the internal API is not running.
      'GITALY_TESTING_NO_GIT_HOOKS' => "1",
      'GITALY_TESTING_ENABLE_ALL_FEATURE_FLAGS' => "true"
    }
  end

  # rubocop:disable GitlabSecurity/SystemCommandInjection
  def set_bundler_config
    system('bundle config set --local jobs 4', chdir: gemfile_dir)
    system('bundle config set --local retry 3', chdir: gemfile_dir)

    if ENV['CI']
      bundle_path = File.expand_path('../../../vendor/gitaly-ruby', __dir__)
      system('bundle', 'config', 'set', '--local', 'path', bundle_path, chdir: gemfile_dir)
    end
  end
  # rubocop:enable GitlabSecurity/SystemCommandInjection

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

  def service_binary(service)
    case service
    when :gitaly, :gitaly2
      'gitaly'
    when :praefect
      'praefect'
    end
  end

  def install_gitaly_gems
    system(env, "make #{tmp_tests_gitaly_dir}/.ruby-bundle", chdir: tmp_tests_gitaly_dir) # rubocop:disable GitlabSecurity/SystemCommandInjection
  end

  def build_gitaly
    system(env, 'make', chdir: tmp_tests_gitaly_dir) # rubocop:disable GitlabSecurity/SystemCommandInjection
  end

  def start_gitaly
    start(:gitaly)
  end

  def start_gitaly2
    start(:gitaly2)
  end

  def start_praefect
    start(:praefect)
  end

  def start(service)
    args = ["#{tmp_tests_gitaly_bin_dir}/#{service_binary(service)}"]
    args.push("-config") if service == :praefect
    args.push(config_path(service))
    pid = spawn(env, *args, [:out, :err] => "log/#{service}-test.log")

    begin
      try_connect!(service)
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
    abort 'bundle check failed' unless system(env, 'bundle', 'check', out: out, chdir: File.dirname(gemfile))
  end

  def read_socket_path(service)
    # This code needs to work in an environment where we cannot use bundler,
    # so we cannot easily use the toml-rb gem. This ad-hoc parser should be
    # good enough.
    config_text = IO.read(config_path(service))

    config_text.lines.each do |line|
      match_data = line.match(/^\s*socket_path\s*=\s*"([^"]*)"$/)

      return match_data[1] if match_data
    end

    raise "failed to find socket_path in #{config_path(service)}"
  end

  def try_connect!(service)
    LOGGER.debug "Trying to connect to #{service}: "
    timeout = 20
    delay = 0.1
    socket = read_socket_path(service)

    Integer(timeout / delay).times do
      UNIXSocket.new(socket)
      LOGGER.debug " OK\n"

      return
    rescue Errno::ENOENT, Errno::ECONNREFUSED
      LOGGER.debug '.'
      sleep delay
    end

    LOGGER.warn " FAILED to connect to #{service}\n"

    raise "could not connect to #{socket}"
  end
end

require 'rspec/mocks'
require 'webrick'

module TestEnv
  extend self

  # Test environment
  #
  # See gitlab.yml.example test section for paths
  #
  def init(opts = {})
    RSpec::Mocks::setup(self)

    # Disable mailer for spinach tests
    disable_mailer if opts[:mailer] == false

    # Clean /tmp/tests
    if File.directory?(tmp_test_path)
      Dir.entries(tmp_test_path).each do |entry|
        unless ['.', '..', 'gitlab-shell'].include?(entry)
          FileUtils.rm_r(File.join(tmp_test_path, entry))
        end
      end
    end

    FileUtils.mkdir_p(tmp_test_path)

    # Setup GitLab shell for test instance
    setup_gitlab_shell

    setup_internal_api_mock

    # Create repository for FactoryGirl.create(:project)
    setup_factory_repo
  end

  def deinit
    destroy_internal_api_mock
  end

  def disable_mailer
    NotificationService.any_instance.stub(mailer: double.as_null_object)
  end

  def enable_mailer
    NotificationService.any_instance.unstub(:mailer)
  end

  def setup_gitlab_shell
    `rake gitlab:shell:install`
  end

  def setup_factory_repo
    clone_url = "https://gitlab.com/gitlab-org/#{factory_repo_name}.git"

    unless File.directory?(factory_repo_path)
      git_cmd = %W(git clone --bare #{clone_url} #{factory_repo_path})
      system(*git_cmd)
    end
  end

  def copy_repo(project)
    base_repo_path = File.expand_path(factory_repo_path)
    target_repo_path = File.expand_path(repos_path + "/#{project.namespace.path}/#{project.path}.git")
    FileUtils.mkdir_p(target_repo_path)
    FileUtils.cp_r("#{base_repo_path}/.", target_repo_path)
    FileUtils.chmod_R 0755, target_repo_path
  end

  def repos_path
    Gitlab.config.gitlab_shell.repos_path
  end

  private

  def factory_repo_path
    @factory_repo_path ||= repos_path + "/root/#{factory_repo_name}.git"
  end

  def factory_repo_name
    'gitlab-test'
  end

  def tmp_test_path
    Rails.root.join('tmp', 'tests')
  end

  def internal_api_mock_pid_path
    File.join(tmp_test_path, 'internal_api_mock.pid')
  end

  # This mock server exists because during testing GitLab is not served
  # on any port, but gitlab-shell needs to ask the GitLab internal API
  # if it is OK to push to repositories. This can happen during blob web
  # edit tests. The server always replies yes: this should not modify affect
  # web interface tests.
  def setup_internal_api_mock
    begin
      server = WEBrick::HTTPServer.new(
        BindAddress: '0.0.0.0',
        Port: Gitlab.config.gitlab.port,
        AccessLog: [],
        Logger: WEBrick::Log.new('/dev/null')
      )
    rescue => ex
      ex.message.prepend('could not start mock server on configured port. ')
      raise ex
    end
    fork do
      trap(:INT) { server.shutdown }
      server.mount_proc('/') do |_req, res|
        res.status = 200
        res.body = 'true'
      end
      WEBrick::Daemon.start do
        File.write(internal_api_mock_pid_path, Process.pid)
      end
      server.start
    end
    # Ideally this should be called from `config.after(:suite)`,
    # but on Spinach when user hits Ctrl+C the server does not get killed
    # if the hook is set up with `Spinach.hooks.after_run`.
    at_exit do
      # The file should exist on normal operation,
      # but certain errors can lead to it not existing.
      if File.exists?(internal_api_mock_pid_path)
        Process.kill(:INT, File.read(internal_api_mock_pid_path).to_i)
      end
    end
  end
end

require 'rspec/mocks'
require 'webrick'

module TestEnv
  extend self

  # When developing the seed repository, comment out the branch you will modify.
  BRANCH_SHA = {
    'feature'          => '0b4bc9a',
    'feature_conflict' => 'bb5206f',
    'fix'              => '12d65c8',
    'improve/awesome'  => '5937ac0',
    'markdown'         => '0ed8c6c',
    'master'           => '5937ac0'
  }

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
        unless ['.', '..', 'gitlab-shell', factory_repo_name].include?(entry)
          FileUtils.rm_r(File.join(tmp_test_path, entry))
        end
      end
    end

    FileUtils.mkdir_p(repos_path)

    # Setup GitLab shell for test instance
    setup_gitlab_shell

    setup_internal_api_mock

    # Create repository for FactoryGirl.create(:project)
    setup_factory_repo
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
      system(*%W(git clone #{clone_url} #{factory_repo_path}))
    end

    Dir.chdir(factory_repo_path) do
      BRANCH_SHA.each do |branch, sha|
        # Try to reset without fetching to avoid using the network.
        reset = %W(git update-ref refs/heads/#{branch} #{sha})
        unless system(*reset)
          if system(*%w(git fetch origin))
            unless system(*reset)
              raise 'The fetched test seed '\
              'does not contain the required revision.'
            end
          else
            raise 'Could not fetch test seed repository.'
          end
        end
      end
    end

    # We must copy bare repositories because we will push to them.
    system(*%W(git clone --bare #{factory_repo_path} #{factory_repo_path_bare}))
  end

  def copy_repo(project)
    base_repo_path = File.expand_path(factory_repo_path_bare)
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
    @factory_repo_path ||= Rails.root.join('tmp', 'tests', factory_repo_name)
  end

  def factory_repo_path_bare
    factory_repo_path.to_s + '_bare'
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

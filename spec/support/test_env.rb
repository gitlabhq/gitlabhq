require 'rspec/mocks'

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
    tmp_test_path = Rails.root.join('tmp', 'tests')

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
end

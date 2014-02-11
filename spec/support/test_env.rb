require 'rspec/mocks'

module TestEnv
  extend self

  # Test environment
  #
  # all repositories and namespaces stored at
  # RAILS_APP/tmp/test-git-base-path
  #
  # Next shell methods are stubbed and return true
  # -  mv_repository
  # -  remove_repository
  # -  add_key
  # -  remove_key
  #
  def init(opts = {})
    RSpec::Mocks::setup(self)

    # Disable observers to improve test speed
    #
    # You can enable it in whole test case where needed by next string:
    #
    #   before(:each) { enable_observers }
    #
    disable_observers if opts[:observers] == false

    # Disable mailer for spinach tests
    disable_mailer if opts[:mailer] == false
    setup_stubs


    clear_test_repo_dir if opts[:init_repos] == true
    setup_test_repos(opts) if opts[:repos] == true
  end

  def enable_observers
    ActiveRecord::Base.observers.enable(:all)
  end

  def disable_observers
    ActiveRecord::Base.observers.disable(:all)
  end

  def disable_mailer
    NotificationService.any_instance.stub(mailer: double.as_null_object)
  end

  def enable_mailer
    NotificationService.any_instance.unstub(:mailer)
  end

  def setup_stubs()
    # Use tmp dir for FS manipulations
    repos_path = testing_path()
    GollumWiki.any_instance.stub(:init_repo) do |path|
      create_temp_repo(File.join(repos_path, "#{path}.git"))
    end

    Gitlab.config.gitlab_shell.stub(repos_path: repos_path)

    Gitlab.config.satellites.stub(path: satellite_path)

    Gitlab::Git::Repository.stub(repos_path: repos_path)

    Gitlab::Shell.any_instance.stub(
      add_repository: true,
      mv_repository: true,
      remove_repository: true,
      update_repository_head: true,
      add_key: true,
      remove_key: true,
      version: '6.3.0'
    )

    Gitlab::Satellite::MergeAction.any_instance.stub(
      merge!: true,
    )

    Gitlab::Satellite::Satellite.any_instance.stub(
      exists?: true,
      destroy: true,
      create: true,
      lock_files_dir: repos_path
    )

    MergeRequest.any_instance.stub(
      check_if_can_be_merged: true
    )
    Repository.any_instance.stub(
      size: 12.45
    )

    ActivityObserver.any_instance.stub(
      current_user: double("current_user", id: 1)
    )
  end

  def clear_repo_dir(namespace, name)
    setup_stubs
    # Clean any .wiki.git that may have been created
    FileUtils.rm_rf File.join(testing_path(), "#{name}.wiki.git")
  end

  def reset_satellite_dir
    setup_stubs
    FileUtils.cd(seed_satellite_path) do
      `git reset --hard --quiet`
      `git clean -fx`
      `git checkout --quiet origin/master`
    end
  end

  # Create a repo and it's satellite
  def create_repo(namespace, name)
    setup_stubs
    repo = repo(namespace, name)

    # Symlink tmp/repositories/gitlabhq to tmp/test-git-base-path/gitlabhq
    system("ln -s -f #{seed_repo_path()} #{repo}")
    create_satellite(repo, namespace, name)
  end

  private

  def testing_path
    Rails.root.join('tmp', 'test-git-base-path')
  end

  def seed_repo_path
    Rails.root.join('tmp', 'repositories', 'gitlabhq')
  end

  def seed_satellite_path
    Rails.root.join('tmp', 'satellite', 'gitlabhq')
  end

  def satellite_path
    "#{testing_path()}/satellite"
  end

  def repo(namespace, name)
    unless (namespace.nil? || namespace.path.nil? || namespace.path.strip.empty?)
      repo = File.join(testing_path(), "#{namespace.path}/#{name}.git")
    else
      repo = File.join(testing_path(), "#{name}.git")
    end
  end

  def satellite(namespace, name)
    unless (namespace.nil? || namespace.path.nil? || namespace.path.strip.empty?)
      satellite_repo = File.join(satellite_path, namespace.path, name)
    else
      satellite_repo = File.join(satellite_path, name)
    end
  end

  def setup_test_repos(opts ={})
    create_repo(nil, 'gitlabhq') #unless opts[:repo].nil? || !opts[:repo].include?('')
    create_repo(nil, 'source_gitlabhq') #unless opts[:repo].nil? || !opts[:repo].include?('source_')
    create_repo(nil, 'target_gitlabhq') #unless opts[:repo].nil? || !opts[:repo].include?('target_')
  end

  def clear_test_repo_dir
    setup_stubs
    # Use tmp dir for FS manipulations
    repos_path = testing_path()
    # Remove tmp/test-git-base-path
    FileUtils.rm_rf Gitlab.config.gitlab_shell.repos_path

    # Recreate tmp/test-git-base-path
    FileUtils.mkdir_p Gitlab.config.gitlab_shell.repos_path

    # Since much more is happening in satellites
    FileUtils.mkdir_p Gitlab.config.satellites.path
  end

  # Create a testing satellite, and clone the source repo into it
  def create_satellite(source_repo, namespace, satellite_name)
    satellite_repo = satellite(namespace, satellite_name)
    # Symlink tmp/satellite/gitlabhq to tmp/test-git-base-path/satellite/gitlabhq, create the directory if it doesn't exist already
    satellite_dir = File.dirname(satellite_repo)
    FileUtils.mkdir_p(satellite_dir) unless File.exists?(satellite_dir)
    system("ln -s -f #{seed_satellite_path} #{satellite_repo}")
  end

  def create_temp_repo(path)
    FileUtils.mkdir_p path
    command = "git init --quiet --bare #{path};"
    system(command)
  end
end

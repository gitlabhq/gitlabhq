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
  def init
    # Use tmp dir for FS manipulations
    repos_path = Rails.root.join('tmp', 'test-git-base-path')
    Gitlab.config.gitlab_shell.stub(repos_path: repos_path)

    GollumWiki.any_instance.stub(:init_repo) do |path|
      create_temp_repo(File.join(repos_path, "#{path}.git"))
    end

    Gitlab::Shell.any_instance.stub(
      add_repository: true,
      mv_repository: true,
      remove_repository: true,
      add_key: true,
      remove_key: true
    )

    Gitlab::Satellite::Satellite.any_instance.stub(
      exists?: true,
      destroy: true,
      create: true
    )

    MergeRequest.any_instance.stub(
      check_if_can_be_merged: true
    )

    Repository.any_instance.stub(
      size: 12.45
    )

    # Remove tmp/test-git-base-path
    FileUtils.rm_rf Gitlab.config.gitlab_shell.repos_path

    # Recreate tmp/test-git-base-path
    FileUtils.mkdir_p Gitlab.config.gitlab_shell.repos_path

    # Symlink tmp/repositories/gitlabhq to tmp/test-git-base-path/gitlabhq
    seed_repo = Rails.root.join('tmp', 'repositories', 'gitlabhq')
    target_repo = File.join(repos_path, 'gitlabhq.git')
    system("ln -s #{seed_repo} #{target_repo}")
  end

  def create_temp_repo(path)
    FileUtils.mkdir_p path
    command = "git init --quiet --bare #{path};"
    system(command)
  end
end

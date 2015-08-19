require 'rspec/mocks'

module TestEnv
  extend self

  # When developing the seed repository, comment out the branch you will modify.
  BRANCH_SHA = {
    'empty-branch'     => '7efb185',
    'flatten-dir'      => 'e56497b',
    'feature'          => '0b4bc9a',
    'feature_conflict' => 'bb5206f',
    'fix'              => '12d65c8',
    'improve/awesome'  => '5937ac0',
    'markdown'         => '0ed8c6c',
    'master'           => '5937ac0',
    "'test'"           => 'e56497b',
  }

  # gitlab-test-fork is a fork of gitlab-fork, but we don't necessarily
  # need to keep all the branches in sync.
  # We currently only need a subset of the branches
  FORKED_BRANCH_SHA = {
    'add-submodule-version-bump' => '3f547c08',
    'master' => '5937ac0'
  }

  # Test environment
  #
  # See gitlab.yml.example test section for paths
  #
  def init(opts = {})
    # Disable mailer for spinach tests
    disable_mailer if opts[:mailer] == false

    clean_test_path

    FileUtils.mkdir_p(repos_path)
    FileUtils.mkdir_p(backup_path)

    # Setup GitLab shell for test instance
    setup_gitlab_shell

    # Create repository for FactoryGirl.create(:project)
    setup_factory_repo

    # Create repository for FactoryGirl.create(:forked_project_with_submodules)
    setup_forked_repo
  end

  def disable_mailer
    allow_any_instance_of(NotificationService).to receive(:mailer).
      and_return(double.as_null_object)
  end

  def enable_mailer
    allow_any_instance_of(NotificationService).to receive(:mailer).
      and_call_original
  end

  def disable_pre_receive
    allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(true)
  end

  # Clean /tmp/tests
  #
  # Keeps gitlab-shell and gitlab-test
  def clean_test_path
    tmp_test_path = Rails.root.join('tmp', 'tests', '**')

    Dir[tmp_test_path].each do |entry|
      unless File.basename(entry) =~ /\Agitlab-(shell|test|test-fork)\z/
        FileUtils.rm_rf(entry)
      end
    end
  end

  def setup_gitlab_shell
    unless File.directory?(Rails.root.join(*%w(tmp tests gitlab-shell)))
      `rake gitlab:shell:install`
    end
  end

  def setup_factory_repo
    setup_repo(factory_repo_path, factory_repo_path_bare, factory_repo_name,
               BRANCH_SHA)
  end

  # This repo has a submodule commit that is not present in the main test
  # repository.
  def setup_forked_repo
    setup_repo(forked_repo_path, forked_repo_path_bare, forked_repo_name,
               FORKED_BRANCH_SHA)
  end

  def setup_repo(repo_path, repo_path_bare, repo_name, branch_sha)
    clone_url = "https://gitlab.com/gitlab-org/#{repo_name}.git"

    unless File.directory?(repo_path)
      system(*%W(git clone -q #{clone_url} #{repo_path}))
    end

    Dir.chdir(repo_path) do
      branch_sha.each do |branch, sha|
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
    system(git_env, *%W(git clone -q --bare #{repo_path} #{repo_path_bare}))
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

  def backup_path
    Gitlab.config.backup.path
  end

  def copy_forked_repo_with_submodules(project)
    base_repo_path = File.expand_path(forked_repo_path_bare)
    target_repo_path = File.expand_path(repos_path + "/#{project.namespace.path}/#{project.path}.git")
    FileUtils.mkdir_p(target_repo_path)
    FileUtils.cp_r("#{base_repo_path}/.", target_repo_path)
    FileUtils.chmod_R 0755, target_repo_path
  end

  private

  def factory_repo_path
    @factory_repo_path ||= Rails.root.join('tmp', 'tests', factory_repo_name)
  end

  def factory_repo_path_bare
    "#{factory_repo_path}_bare"
  end

  def factory_repo_name
    'gitlab-test'
  end

  def forked_repo_path
    @forked_repo_path ||= Rails.root.join('tmp', 'tests', forked_repo_name)
  end

  def forked_repo_path_bare
    "#{forked_repo_path}_bare"
  end

  def forked_repo_name
    'gitlab-test-fork'
  end


  # Prevent developer git configurations from being persisted to test
  # repositories
  def git_env
    { 'GIT_TEMPLATE_DIR' => '' }
  end
end

require 'rake_helper'

describe 'gitlab:shell rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/shell'

    stub_warn_user_is_not_gitlab
  end

  describe 'install task' do
    it 'invokes create_hooks task' do
      expect(Rake::Task['gitlab:shell:create_hooks']).to receive(:invoke)

      storages = Gitlab.config.repositories.storages.values.map(&:legacy_disk_path)
      expect(Kernel).to receive(:system).with('bin/install', *storages).and_call_original
      expect(Kernel).to receive(:system).with('bin/compile').and_call_original

      run_rake_task('gitlab:shell:install')
    end
  end

  describe 'create_hooks task' do
    it 'calls gitlab-shell bin/create_hooks' do
      expect_any_instance_of(Object).to receive(:system)
        .with("#{Gitlab.config.gitlab_shell.path}/bin/create-hooks",
              *Gitlab::TaskHelpers.repository_storage_paths_args)

      run_rake_task('gitlab:shell:create_hooks')
    end
  end
end

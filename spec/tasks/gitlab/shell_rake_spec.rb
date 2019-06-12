require 'rake_helper'

describe 'gitlab:shell rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/shell'

    stub_warn_user_is_not_gitlab
  end

  describe 'install task' do
    it 'installs and compiles gitlab-shell' do
      storages = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        Gitlab.config.repositories.storages.values.map(&:legacy_disk_path)
      end
      expect(Kernel).to receive(:system).with('bin/install', *storages).and_call_original
      expect(Kernel).to receive(:system).with('bin/compile').and_call_original

      run_rake_task('gitlab:shell:install')
    end
  end
end

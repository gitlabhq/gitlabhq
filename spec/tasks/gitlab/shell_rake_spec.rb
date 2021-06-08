# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:shell rake tasks', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/shell'

    stub_warn_user_is_not_gitlab
  end

  describe 'install task' do
    it 'installs and compiles gitlab-shell' do
      storages = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        Gitlab.config.repositories.storages.values.map(&:legacy_disk_path)
      end

      expect_any_instance_of(Gitlab::TaskHelpers).to receive(:checkout_or_clone_version)
      allow(Kernel).to receive(:system).with('bin/install', *storages).and_return(true)
      allow(Kernel).to receive(:system).with('make', 'build').and_return(true)

      run_rake_task('gitlab:shell:install')
    end
  end
end

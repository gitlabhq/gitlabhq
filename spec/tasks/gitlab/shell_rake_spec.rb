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

  describe 'setup task' do
    it 'writes authorized keys into the file' do
      allow(Gitlab::CurrentSettings).to receive(:authorized_keys_enabled?).and_return(true)
      stub_env('force', 'yes')

      auth_key = create(:key)
      auth_and_signing_key = create(:key, usage_type: :auth_and_signing)
      create(:key, usage_type: :signing)

      expect_next_instance_of(Gitlab::AuthorizedKeys) do |instance|
        expect(instance).to receive(:batch_add_keys).once do |keys|
          expect(keys).to match_array([auth_key, auth_and_signing_key])
        end
      end

      run_rake_task('gitlab:shell:setup')
    end
  end
end

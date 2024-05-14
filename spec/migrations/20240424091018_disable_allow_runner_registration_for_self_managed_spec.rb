# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DisableAllowRunnerRegistrationForSelfManaged, '#up', feature_category: :runner do
  let!(:application_settings_table) { table(:application_settings) }

  shared_examples 'a migration disabling allow_runner_registration_token' do
    context 'when application setting does not exist' do
      it 'creates new application_setting set to false' do
        expect { migrate! }.to change { application_settings_table.count }.from(0).to(1)
        expect(application_settings_table.last.allow_runner_registration_token).to be_falsey
      end
    end

    context 'when application setting exists' do
      let!(:application_setting) do
        application_settings_table.create!(id: 1, allow_runner_registration_token: allow_runner_registration_token)
      end

      context 'with allow_runner_registration_token set to true' do
        let(:allow_runner_registration_token) { true }

        it 'sets application_setting to false' do
          expect { migrate! }.to change { application_setting.reload.allow_runner_registration_token }
            .from(true).to(false)
        end
      end

      context 'with allow_runner_registration_token set to false' do
        let(:allow_runner_registration_token) { false }

        it 'does not change application_setting' do
          expect { migrate! }.not_to change { application_setting.reload.allow_runner_registration_token }
        end
      end
    end
  end

  shared_examples 'a migration leaving allow_runner_registration_token unchanged' do
    context 'when application setting does not exist' do
      it 'does not create new application_setting' do
        expect { migrate! }.not_to change { application_settings_table.count }
        expect(application_settings_table.last).to be_nil
      end
    end

    context 'when application setting exists' do
      let!(:application_setting) do
        application_settings_table.create!(id: 1, allow_runner_registration_token: allow_runner_registration_token)
      end

      context 'with allow_runner_registration_token set to true' do
        let(:allow_runner_registration_token) { true }

        it 'does not change application_setting' do
          expect { migrate! }.not_to change { application_setting.reload.allow_runner_registration_token }
        end
      end

      context 'with allow_runner_registration_token set to false' do
        let(:allow_runner_registration_token) { false }

        it 'does not change application_setting' do
          expect { migrate! }.not_to change { application_setting.reload.allow_runner_registration_token }
        end
      end
    end
  end

  context 'when on self-managed' do
    it_behaves_like 'a migration disabling allow_runner_registration_token'
  end

  context 'when instance is dedicated' do
    before do
      Gitlab::CurrentSettings.update!(gitlab_dedicated_instance: true)
    end

    it_behaves_like 'a migration disabling allow_runner_registration_token'
  end

  context 'when on SaaS', :saas do
    it_behaves_like 'a migration leaving allow_runner_registration_token unchanged'
  end
end

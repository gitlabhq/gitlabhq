# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::CreateGroupO11ySettingWorker, feature_category: :observability do
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let(:worker) { described_class.new }

  before do
    stub_request(:post, Observability::O11yProvisioningClient::PROVISIONER_API)
      .to_return(status: 200, body: '{"status": "success"}')
  end

  shared_examples 'does not create observability setting' do
    it 'does not create an observability setting for the group' do
      expect { perform }.not_to change { group.reload.observability_group_o11y_setting }
    end
  end

  shared_examples 'creates observability setting' do
    it 'creates an observability setting for the group' do
      expect { perform }.to change { group.reload.observability_group_o11y_setting }.from(nil)

      setting = group.observability_group_o11y_setting
      expect(setting).to be_present
      expect(setting.o11y_service_name).to eq(group.id.to_s)
      expect(setting.o11y_service_user_email).to eq("#{group.id}@gitlab-o11y.com")
      expect(setting.o11y_service_password).to be_present
      expect(setting.o11y_service_post_message_encryption_key).to be_present
    end
  end

  shared_examples 'logs status' do |status, error_message = nil|
    it "logs #{status} status" do
      allow(worker).to receive(:log_extra_metadata_on_done)

      perform

      expect(worker).to have_received(:log_extra_metadata_on_done).with(:status, status.to_s)
      expect(worker).to have_received(:log_extra_metadata_on_done).with(:group_id, group.id)

      expect(worker).to have_received(:log_extra_metadata_on_done).with(:error, error_message) if error_message
    end
  end

  shared_examples 'logs error' do |expected_message, expected_error = nil|
    it 'logs an error message' do
      allow(Gitlab::AppLogger).to receive(:error).and_call_original

      perform

      expected_group_id = defined?(group_id) ? group_id : group.id
      expected_user_id = defined?(user_id) ? user_id : user.id

      expected_hash_args = {
        message: expected_message,
        group_id: expected_group_id,
        user_id: expected_user_id
      }
      expected_hash_args[:error] = expected_error if expected_error

      expect(Gitlab::AppLogger).to have_received(:error).with(hash_including(expected_hash_args))
    end
  end

  describe '#perform' do
    subject(:perform) { worker.perform(user.id, group.id) }

    context 'when user is not found' do
      subject(:perform) { worker.perform(non_existing_record_id, group.id) }

      include_examples 'does not create observability setting'
    end

    context 'when group is not found' do
      subject(:perform) { worker.perform(user.id, non_existing_record_id) }

      include_examples 'does not create observability setting'
    end

    context 'when both user and group exist' do
      context 'when API call succeeds' do
        include_examples 'creates observability setting'

        it 'makes an API request to the provisioner service' do
          perform

          expect(WebMock).to have_requested(:post, Observability::O11yProvisioningClient::PROVISIONER_API)
            .with(
              body: hash_including(
                'o11y_provision_request' => hash_including(
                  'group_id' => group.id,
                  'email' => user.email,
                  'password' => match(/\A[a-f0-9]{32}\z/),
                  'encryption_key' => match(/\A[a-f0-9]{64}\z/)
                )
              )
            )
        end

        it 'generates secure random tokens for the setting' do
          perform

          setting = group.reload.observability_group_o11y_setting
          expect(setting.o11y_service_password).to match(/\A[a-f0-9]{32}\z/)
          expect(setting.o11y_service_post_message_encryption_key).to match(/\A[a-f0-9]{64}\z/)
        end

        it 'creates CI variable with correct attributes' do
          expect { perform }.to change { group.reload.variables.count }.by(1)

          variable = group.variables.find_by(key: 'GITLAB_OBSERVABILITY_EXPORT')
          expect(variable).to be_present
          expect(variable.value).to eq('traces,metrics,logs')
          expect(variable.variable_type).to eq('env_var')
          expect(variable.protected).to be(false)
          expect(variable.masked).to be(false)
          expect(variable.raw).to be(false)
        end

        include_examples 'logs status', :success

        context 'when CI variable creation fails' do
          before do
            create(:ci_group_variable, group: group, key: 'GITLAB_OBSERVABILITY_EXPORT')
            allow_next_instance_of(Ci::ChangeVariablesService) do |instance|
              allow(instance).to receive(:execute).and_return(false)
            end
          end

          it 'still creates the observability setting' do
            expect { perform }.to change { group.reload.observability_group_o11y_setting }.from(nil)
          end

          it 'does not create an additional CI variable' do
            initial_count = group.reload.variables.count
            expect { perform }.not_to change { group.reload.variables.count }
            expect(group.reload.variables.count).to eq(initial_count)
          end

          include_examples 'logs error', 'Failed to create CI variable for observability export'
        end

        context 'when in production environment' do
          before do
            allow(Rails.env).to receive(:production?).and_return(true)
            production_group = create(:group, id: Observability::O11yProvisioningClient::PRODUCTION_GROUP_ID)
            create(:observability_group_o11y_setting, group: production_group,
              o11y_service_post_message_encryption_key: 'production-encryption-key')
          end

          include_examples 'creates observability setting'

          it 'works correctly in production environment' do
            expect { perform }.to change { group.reload.observability_group_o11y_setting }.from(nil)
          end
        end
      end

      context 'when API request fails' do
        before do
          stub_request(:post, Observability::O11yProvisioningClient::PROVISIONER_API)
            .to_return(status: 500, body: 'Server Error')
        end

        include_examples 'does not create observability setting'

        it 'does not create an observability setting when API fails' do
          expect { perform }.not_to change { group.reload.observability_group_o11y_setting }
        end

        include_examples 'logs status', :api_failed

        it 'logs an error message' do
          allow(Gitlab::AppLogger).to receive(:error).and_call_original

          perform

          expect(Gitlab::AppLogger).to have_received(:error).with(
            hash_including(
              message: be_a(String),
              group_id: group.id,
              user_id: user.id
            )
          )
        end
      end

      context 'when API request raises an error' do
        before do
          stub_request(:post, Observability::O11yProvisioningClient::PROVISIONER_API)
            .to_raise(EOFError.new('Network error'))
        end

        include_examples 'does not create observability setting'
      end

      context 'when group already has observability setting' do
        let!(:existing_setting) { create(:observability_group_o11y_setting, group: group) }

        include_examples 'does not create observability setting'

        it 'does not make an API request when setting already exists' do
          perform

          expect(WebMock).not_to have_requested(:post, Observability::O11yProvisioningClient::PROVISIONER_API)
        end
      end

      context 'when database save fails after successful API call' do
        before do
          allow_next_instance_of(::Observability::GroupO11ySettingsUpdateService) do |instance|
            allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Database error'))
          end
        end

        include_examples 'does not create observability setting'

        it 'does not create setting when database save fails' do
          expect { perform }.not_to change { group.reload.observability_group_o11y_setting }
        end
      end

      context 'when logging security' do
        let(:logged_messages) { [] }
        let(:sensitive_fields) { %w[o11y_service_password o11y_service_post_message_encryption_key] }

        before do
          allow(Rails.logger).to receive_messages(info: nil, debug: nil, warn: nil, error: nil)
          allow(Rails.logger).to receive(:info) { |msg| logged_messages << msg }
          allow(Rails.logger).to receive(:debug) { |msg| logged_messages << msg }
          allow(Rails.logger).to receive(:error) { |msg| logged_messages << msg }

          if defined?(Gitlab::AppLogger)
            allow(Gitlab::AppLogger).to receive(:info) { |msg| logged_messages << msg }
            allow(Gitlab::AppLogger).to receive(:debug) { |msg| logged_messages << msg }
            allow(Gitlab::AppLogger).to receive(:error) { |msg| logged_messages << msg }
          end

          allow(Sidekiq.logger).to receive(:info) { |msg| logged_messages << msg }
          allow(Sidekiq.logger).to receive(:debug) { |msg| logged_messages << msg }
          allow(Sidekiq.logger).to receive(:warn) { |msg| logged_messages << msg }
          allow(Sidekiq.logger).to receive(:error) { |msg| logged_messages << msg }
        end

        shared_examples 'does not log sensitive values' do
          it 'never logs actual password or encryption key values' do
            perform

            setting = group.reload.observability_group_o11y_setting

            if setting.nil?
              logged_messages.each do |message|
                message_str = message.to_s

                sensitive_fields.each do |field|
                  expect(message_str).to match(/\[FILTERED\]|\[REDACTED\]|\*{3,}/) if message_str.include?(field)
                end
              end
            else
              sensitive_values = [
                setting.o11y_service_password,
                setting.o11y_service_post_message_encryption_key
              ]

              logged_messages.each do |message|
                message_str = message.to_s

                sensitive_values.each do |value|
                  expect(message_str).not_to include(value)
                end
              end
            end
          end
        end

        context 'when successful operation' do
          include_examples 'does not log sensitive values'
        end

        context 'when API request fails' do
          before do
            stub_request(:post, Observability::O11yProvisioningClient::PROVISIONER_API)
              .to_return(status: 500, body: 'Server Error')
          end

          include_examples 'does not log sensitive values'
        end
      end
    end
  end
end

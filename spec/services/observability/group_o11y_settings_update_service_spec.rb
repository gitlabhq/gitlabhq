# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::GroupO11ySettingsUpdateService, feature_category: :observability do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:settings) { create(:observability_group_o11y_setting, group: group) }

  let(:service) { described_class.new }
  let(:settings_params) { {} }

  before_all do
    group.add_owner(user)
  end

  describe '#execute' do
    subject(:execute) { service.execute(settings, settings_params) }

    context 'when update succeeds' do
      it 'filters blank parameters before updating' do
        params_with_blanks = {
          o11y_service_url: 'https://new-example.com',
          o11y_service_user_email: '',
          o11y_service_password: nil,
          o11y_service_post_message_encryption_key: ''
        }

        expect(settings).to receive(:update)
                        .with({ o11y_service_url: 'https://new-example.com' })
                        .and_return(true)

        result = service.execute(settings, params_with_blanks)
        expect(result).to be_success
        expect(result.payload[:settings]).to eq(settings)
      end

      it 'updates settings with valid parameters' do
        valid_params = {
          o11y_service_url: 'https://new-example.com',
          o11y_service_user_email: 'new@example.com',
          o11y_service_password: 'password',
          o11y_service_post_message_encryption_key: 'key'
        }

        expect(settings).to receive(:update).with(valid_params).and_return(true)

        result = service.execute(settings, valid_params)
        expect(result).to be_success
        expect(result.payload[:settings]).to eq(settings)
      end

      it 'handles parameters with only blank values by filtering to empty hash' do
        blank_params = {
          o11y_service_url: '',
          o11y_service_user_email: nil,
          o11y_service_password: '  '
        }

        expect(settings).to receive(:update).with({}).and_return(true)

        result = service.execute(settings, blank_params)
        expect(result).to be_success
        expect(result.payload[:settings]).to eq(settings)
      end

      it 'handles empty parameters hash' do
        expect(settings).to receive(:update).with({}).and_return(true)

        result = service.execute(settings, {})
        expect(result).to be_success
        expect(result.payload[:settings]).to eq(settings)
      end
    end

    context 'when update fails' do
      it 'returns error response when update fails' do
        error_message = "Validation failed"
        allow(settings).to receive(:update).and_return(false)
        allow(settings).to receive_message_chain(:errors, :full_messages).and_return([error_message])

        result = service.execute(settings, settings_params)
        expect(result).to be_error
        expect(result.message).to eq(error_message)
      end

      it 'returns error response with multiple validation errors' do
        error_messages = ["URL is invalid", "Email is required"]
        allow(settings).to receive(:update).and_return(false)
        allow(settings).to receive_message_chain(:errors, :full_messages).and_return(error_messages)

        result = service.execute(settings, settings_params)
        expect(result).to be_error
        expect(result.message).to eq("URL is invalid, Email is required")
      end

      it 'handles ActiveRecord::RecordInvalid exception' do
        invalid_record_error = ActiveRecord::RecordInvalid.new(settings)
        allow(settings).to receive(:update).and_raise(invalid_record_error)

        result = service.execute(settings, settings_params)
        expect(result).to be_error
        expect(result.message).to eq(invalid_record_error.message)
      end

      it 'handles ActiveRecord::RecordNotFound exception' do
        not_found_error = ActiveRecord::RecordNotFound.new('Setting not found')
        allow(settings).to receive(:update).and_raise(not_found_error)

        result = service.execute(settings, settings_params)
        expect(result).to be_error
        expect(result.message).to eq(not_found_error.message)
      end

      it 'handles StandardError exception' do
        error_message = "An unexpected error occurred"
        allow(settings).to receive(:update).and_raise(StandardError.new(error_message))

        result = service.execute(settings, settings_params)
        expect(result).to be_error
        expect(result.message).to eq("An unexpected error occurred: #{error_message}")
      end
    end
  end

  describe 'private methods' do
    describe '#filter_blank_params' do
      it 'removes blank values (empty strings, nil, whitespace)' do
        params = { key1: 'value1', key2: '', key3: nil, key4: '  ', key5: 'value5' }
        result = service.send(:filter_blank_params, params)
        expect(result).to eq({ key1: 'value1', key5: 'value5' })
      end

      it 'keeps non-blank values unchanged' do
        params = { key1: 'value1', key2: 'value2', key3: 'value3' }
        result = service.send(:filter_blank_params, params)
        expect(result).to eq(params)
      end

      it 'handles empty hash' do
        result = service.send(:filter_blank_params, {})
        expect(result).to eq({})
      end

      it 'handles non-string values correctly' do
        params = { key1: 'value1', key2: false, key3: 'value3', key4: 'value' }
        result = service.send(:filter_blank_params, params)
        expect(result).to eq({ key1: 'value1', key3: 'value3', key4: 'value' })
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::AppleAppStore, feature_category: :mobile_devops do
  describe 'Validations' do
    context 'when active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :app_store_issuer_id }
      it { is_expected.to validate_presence_of :app_store_key_id }
      it { is_expected.to validate_presence_of :app_store_private_key }
      it { is_expected.to validate_presence_of :app_store_private_key_file_name }
      it { is_expected.to allow_value('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee').for(:app_store_issuer_id) }
      it { is_expected.not_to allow_value('abcde').for(:app_store_issuer_id) }
      it { is_expected.to allow_value(File.read('spec/fixtures/ssl_key.pem')).for(:app_store_private_key) }
      it { is_expected.not_to allow_value("foo").for(:app_store_private_key) }
      it { is_expected.to allow_value('ABCD1EF12G').for(:app_store_key_id) }
      it { is_expected.not_to allow_value('ABC').for(:app_store_key_id) }
      it { is_expected.not_to allow_value('abc1').for(:app_store_key_id) }
      it { is_expected.not_to allow_value('-A0-').for(:app_store_key_id) }
    end
  end

  context 'when integration is enabled' do
    let(:apple_app_store_integration) { build(:apple_app_store_integration) }

    describe '#fields' do
      it 'returns custom fields' do
        expect(apple_app_store_integration.fields.pluck(:name)).to match_array(%w[app_store_issuer_id app_store_key_id
          app_store_private_key app_store_private_key_file_name])
      end
    end

    describe '#test' do
      it 'returns true for a successful request' do
        allow(AppStoreConnect::Client).to receive_message_chain(:new, :apps).and_return({})
        expect(apple_app_store_integration.test[:success]).to be true
      end

      it 'returns false for an invalid request' do
        allow(AppStoreConnect::Client).to receive_message_chain(:new,
:apps).and_return({ errors: [title: "error title"] })
        expect(apple_app_store_integration.test[:success]).to be false
      end
    end

    describe '#help' do
      it 'renders prompt information' do
        expect(apple_app_store_integration.help).not_to be_empty
      end
    end

    describe '.to_param' do
      it 'returns the name of the integration' do
        expect(described_class.to_param).to eq('apple_app_store')
      end
    end

    describe '#ci_variables' do
      let(:apple_app_store_integration) { build_stubbed(:apple_app_store_integration) }

      it 'returns vars when the integration is activated' do
        ci_vars = [
          {
            key: 'APP_STORE_CONNECT_API_KEY_ISSUER_ID',
            value: apple_app_store_integration.app_store_issuer_id,
            masked: true,
            public: false
          },
          {
            key: 'APP_STORE_CONNECT_API_KEY_KEY',
            value: Base64.encode64(apple_app_store_integration.app_store_private_key),
            masked: true,
            public: false
          },
          {
            key: 'APP_STORE_CONNECT_API_KEY_KEY_ID',
            value: apple_app_store_integration.app_store_key_id,
            masked: true,
            public: false
          },
          {
            key: 'APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64',
            value: described_class::IS_KEY_CONTENT_BASE64,
            masked: false,
            public: false
          }
        ]

        expect(apple_app_store_integration.ci_variables).to match_array(ci_vars)
      end

      it 'returns an empty array when the integration is disabled' do
        apple_app_store_integration = build_stubbed(:apple_app_store_integration, active: false)
        expect(apple_app_store_integration.ci_variables).to match_array([])
      end
    end
  end

  context 'when integration is disabled' do
    let(:apple_app_store_integration) { build_stubbed(:apple_app_store_integration, active: false) }

    describe '#ci_variables' do
      it 'returns an empty array' do
        expect(apple_app_store_integration.ci_variables).to match_array([])
      end
    end
  end
end

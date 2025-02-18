# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::AppleAppStore, feature_category: :mobile_devops do
  subject(:integration) { build(:apple_app_store_integration) }

  describe 'Validations' do
    context 'when active' do
      it { is_expected.to validate_presence_of :app_store_issuer_id }
      it { is_expected.to validate_presence_of :app_store_key_id }
      it { is_expected.to validate_presence_of :app_store_private_key }
      it { is_expected.to validate_presence_of :app_store_private_key_file_name }
      it { is_expected.to validate_inclusion_of(:app_store_protected_refs).in_array([true, false]) }
      it { is_expected.to allow_value('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee').for(:app_store_issuer_id) }
      it { is_expected.to allow_value(File.read('spec/fixtures/ssl_key.pem')).for(:app_store_private_key) }
      it { is_expected.to allow_value('ABCD1EF12G').for(:app_store_key_id) }
      it { is_expected.not_to allow_value('abcde').for(:app_store_issuer_id) }
      it { is_expected.not_to allow_value("foo").for(:app_store_private_key) }
      it { is_expected.not_to allow_value('ABC').for(:app_store_key_id) }
      it { is_expected.not_to allow_value('abc1').for(:app_store_key_id) }
      it { is_expected.not_to allow_value('-A0-').for(:app_store_key_id) }
    end

    context 'when inactive' do
      before do
        integration.deactivate!
      end

      it { is_expected.not_to validate_presence_of :app_store_issuer_id }
      it { is_expected.not_to validate_presence_of :app_store_key_id }
      it { is_expected.not_to validate_presence_of :app_store_private_key }
      it { is_expected.not_to validate_presence_of :app_store_private_key_file_name }
      it { is_expected.not_to validate_inclusion_of(:app_store_protected_refs).in_array([true, false]) }
    end
  end

  describe '#fields' do
    it 'returns custom fields' do
      expect(integration.fields.pluck(:name)).to match_array(%w[app_store_issuer_id app_store_key_id
        app_store_private_key app_store_private_key_file_name app_store_protected_refs])
    end
  end

  describe '#test' do
    it 'returns true for a successful request' do
      allow(AppStoreConnect::Client).to receive_message_chain(:new, :apps).and_return({})
      expect(integration.test[:success]).to be true
    end

    it 'returns false for an invalid request' do
      allow(AppStoreConnect::Client).to receive_message_chain(:new, :apps)
        .and_return({ errors: [title: "error title"] })
      expect(integration.test[:success]).to be false
    end
  end

  describe '#help' do
    it { expect(integration.help).not_to be_empty }
  end

  describe '.to_param' do
    it { expect(integration.to_param).to eq('apple_app_store') }
  end

  describe '#ci_variables' do
    let(:ci_vars) do
      [
        {
          key: 'APP_STORE_CONNECT_API_KEY_ISSUER_ID',
          value: integration.app_store_issuer_id,
          masked: true,
          public: false
        },
        {
          key: 'APP_STORE_CONNECT_API_KEY_KEY',
          value: Base64.encode64(integration.app_store_private_key),
          masked: true,
          public: false
        },
        {
          key: 'APP_STORE_CONNECT_API_KEY_KEY_ID',
          value: integration.app_store_key_id,
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
    end

    it 'returns the vars for protected branch' do
      expect(integration.ci_variables(protected_ref: true)).to match_array(ci_vars)
    end

    it 'doesn\'t return the vars for unprotected branch' do
      expect(integration.ci_variables(protected_ref: false)).to be_empty
    end
  end

  describe '#initialize_properties' do
    context 'when `app_store_protected_refs` is nil' do
      subject(:integration) { described_class.new(app_store_protected_refs: nil) }

      it { expect(integration.app_store_protected_refs).to be(true) }
    end

    context 'when `app_store_protected_refs` is false' do
      subject(:integration) { described_class.new(app_store_protected_refs: false) }

      it { expect(integration.app_store_protected_refs).to be(false) }
    end
  end

  context 'when integration is disabled' do
    before do
      integration.deactivate!
    end

    describe '#ci_variables' do
      it { expect(integration.ci_variables(protected_ref: true)).to be_empty }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::BeyondIdentity, feature_category: :integrations do
  subject(:integration) { create(:beyond_identity_integration) }

  describe 'validations' do
    context 'when inactive' do
      before do
        integration.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
    end

    context 'when active' do
      it { is_expected.to validate_presence_of(:token) }
    end
  end

  describe 'attributes' do
    it 'configures attributes' do
      expect(integration.supported_events).to be_blank
      expect(integration.to_param).to eq('beyond_identity')
      expect(integration.title).to eq('Beyond Identity')

      expect(integration.description).to eq(
        'Verify that GPG keys are authorized by Beyond Identity Authenticator.'
      )

      expect(integration.help).to include(
        'Verify that GPG keys are authorized by Beyond Identity Authenticator.'
      )
    end
  end

  describe '.api_arguments' do
    it 'returns api arguments' do
      expect(described_class.api_arguments).to eq([{
        required: true,
        name: :token,
        type: String,
        desc: 'API Token. User must have access to `git-commit-signing` endpoint.'
      }, {
        required: false,
        name: :exclude_service_accounts,
        type: Grape::API::Boolean,
        desc: "If enabled, Beyond Identity will not check commits from service accounts."
      }])
    end
  end

  describe '#execute' do
    it 'performs a request to beyond identity service' do
      params = { key_id: 'key-id', committer_email: 'email' }
      response = 'response'

      expect_next_instance_of(::Gitlab::BeyondIdentity::Client) do |instance|
        expect(instance).to receive(:execute).with(params).and_return(response)
      end

      expect(integration.execute(params)).to eq(response)
    end
  end

  describe '.activated_for_instance?' do
    let!(:integration) { create(:beyond_identity_integration, instance: instance, active: active, group: group) }
    let_it_be(:group_for_integration) { create(:group) }

    subject { described_class.activated_for_instance? }

    using RSpec::Parameterized::TableSyntax

    where(:instance, :group, :active, :expected) do
      true  | nil | true | true
      false | lazy { group_for_integration } | true | false
      true  | nil | false | false
      false | lazy { group_for_integration } | false | false
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end
end

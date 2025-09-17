# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentToken, feature_category: :deployment_management do
  include ::TokenAuthenticatableMatchers

  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to validate_presence_of(:name) }

  it_behaves_like 'having unique enum values'

  describe 'scopes' do
    let_it_be(:agent) { create(:cluster_agent) }

    describe '.order_last_used_at_desc' do
      let_it_be(:token_1) { create(:cluster_agent_token, agent: agent, last_used_at: 7.days.ago) }
      let_it_be(:token_2) { create(:cluster_agent_token, agent: agent, last_used_at: nil) }
      let_it_be(:token_3) { create(:cluster_agent_token, agent: agent, last_used_at: 2.days.ago) }

      it 'sorts by last_used_at descending, with null values at last' do
        expect(described_class.order_last_used_at_desc)
          .to eq([token_3, token_1, token_2])
      end
    end

    describe 'status-related scopes' do
      let!(:active_token) { create(:cluster_agent_token, agent: agent) }
      let!(:revoked_token) { create(:cluster_agent_token, :revoked, agent: agent) }

      describe '.with_status' do
        context 'when filtering by active status' do
          subject { described_class.with_status(:active) }

          it { is_expected.to contain_exactly(active_token) }
        end

        context 'when filtering by revoked status' do
          subject { described_class.with_status(:revoked) }

          it { is_expected.to contain_exactly(revoked_token) }
        end
      end

      describe '.active' do
        subject { described_class.active }

        it { is_expected.to contain_exactly(active_token) }
      end
    end

    describe '.connected' do
      let!(:token) { create(:cluster_agent_token, agent: agent, status: status, last_used_at: last_used_at) }

      let(:status) { :active }
      let(:last_used_at) { 2.minutes.ago }

      subject { described_class.connected }

      it { is_expected.to contain_exactly(token) }

      context 'when the token has not been used recently' do
        let(:last_used_at) { 2.hours.ago }

        it { is_expected.to be_empty }
      end

      context 'when the token is not active' do
        let(:status) { :revoked }

        it { is_expected.to be_empty }
      end
    end
  end

  describe '#token' do
    shared_examples 'has a prefix' do
      it 'starts with prefix' do
        agent_token = build(:cluster_agent_token, token_encrypted: nil)
        agent_token.save!

        expect(agent_token.token).to start_with expected_prefix
      end
    end

    it 'is generated on save' do
      agent_token = build(:cluster_agent_token, token_encrypted: nil)
      expect(agent_token.token).to be_nil

      agent_token.save!

      expect(agent_token.token).to be_present
    end

    it 'is at least 50 characters' do
      agent_token = create(:cluster_agent_token)
      expect(agent_token.token.length).to be >= 50
    end

    it_behaves_like 'has a prefix' do
      let(:expected_prefix) { described_class::TOKEN_PREFIX }
    end

    it 'is revoked on revoke!' do
      agent_token = build(:cluster_agent_token, token_encrypted: nil)
      agent_token.save!

      agent_token.revoke!

      expect(agent_token.active?).to be_falsey
    end

    context 'with instance prefix configured' do
      let(:instance_prefix) { 'instanceprefix' }
      let(:expected_prefix) { "#{instance_prefix}-#{described_class::TOKEN_PREFIX}" }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it_behaves_like 'has a prefix' do
        let(:expected_prefix) { "#{instance_prefix}-#{described_class::TOKEN_PREFIX}" }
      end

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it_behaves_like 'has a prefix' do
          let(:expected_prefix) { described_class::TOKEN_PREFIX }
        end
      end
    end

    context 'with routable cluster agent token feature flag disabled' do
      let(:agent_token) { create(:cluster_agent_token) }
      let(:token_owner_record) { agent_token }
      let(:expected_token_prefix) { described_class::TOKEN_PREFIX }
      let(:devise_token) { 'devise-token' }

      before do
        stub_feature_flags(routable_cluster_agent_token: false)

        allow(Devise).to receive(:friendly_token).and_return(devise_token)
      end

      subject(:token) { token_owner_record.token }

      it_behaves_like 'an encrypted token' do
        let(:expected_token) { token }
        let(:expected_token_payload) { devise_token }
        let(:expected_encrypted_token) { token_owner_record.token_encrypted }
      end
    end

    context 'with routable cluster agent token feature flag enabled' do
      before do
        stub_feature_flags(routable_cluster_agent_token: true)
      end

      include_context "with token authenticatable routable token context"

      describe "encrypted routable token" do
        let(:agent_token) { create(:cluster_agent_token) }
        let(:token_owner_record) { agent_token }
        let(:expected_token_prefix) { described_class::TOKEN_PREFIX }

        let(:expected_routing_payload) do
          "c:1\n" \
            "o:#{agent_token.agent.project.organization.id.to_s(36)}\n" \
            "p:#{agent_token.project.id.to_s(36)}"
        end

        subject(:token) { token_owner_record.token }

        it_behaves_like "an encrypted routable token" do
          let(:expected_token) { token }
          let(:expected_random_bytes) { random_bytes }
          let(:expected_encrypted_token) { token_owner_record.token_encrypted }
        end
      end
    end
  end

  describe '#to_ability_name' do
    it 'is :cluster' do
      agent_token = build(:cluster_agent_token)

      expect(agent_token.to_ability_name).to eq :cluster
    end
  end
end

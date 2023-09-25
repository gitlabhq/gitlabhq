# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentToken, feature_category: :deployment_management do
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

    it 'has a prefix' do
      agent_token = build(:cluster_agent_token, token_encrypted: nil)
      agent_token.save!

      expect(agent_token.token).to start_with described_class::TOKEN_PREFIX
    end

    it 'is revoked on revoke!' do
      agent_token = build(:cluster_agent_token, token_encrypted: nil)
      agent_token.save!

      agent_token.revoke!

      expect(agent_token.active?).to be_falsey
    end
  end

  describe '#to_ability_name' do
    it 'is :cluster' do
      agent_token = build(:cluster_agent_token)

      expect(agent_token.to_ability_name).to eq :cluster
    end
  end
end

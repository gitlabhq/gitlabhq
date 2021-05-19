# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentToken do
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to validate_presence_of(:name) }

  describe 'scopes' do
    describe '.order_last_used_at_desc' do
      let_it_be(:token_1) { create(:cluster_agent_token, last_used_at: 7.days.ago) }
      let_it_be(:token_2) { create(:cluster_agent_token, last_used_at: nil) }
      let_it_be(:token_3) { create(:cluster_agent_token, last_used_at: 2.days.ago) }

      it 'sorts by last_used_at descending, with null values at last' do
        expect(described_class.order_last_used_at_desc)
          .to eq([token_3, token_1, token_2])
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
  end

  describe '#track_usage', :clean_gitlab_redis_cache do
    let(:agent_token) { create(:cluster_agent_token) }

    subject { agent_token.track_usage }

    context 'when last_used_at was updated recently' do
      before do
        agent_token.update!(last_used_at: 10.minutes.ago)
      end

      it 'updates cache but not database' do
        expect { subject }.not_to change { agent_token.reload.read_attribute(:last_used_at) }

        expect_redis_update
      end
    end

    context 'when last_used_at was not updated recently' do
      it 'updates cache and database' do
        does_db_update
        expect_redis_update
      end

      context 'with invalid token' do
        before do
          agent_token.description = SecureRandom.hex(2000)
        end

        it 'still updates caches and database' do
          expect(agent_token).to be_invalid

          does_db_update
          expect_redis_update
        end
      end
    end

    def expect_redis_update
      Gitlab::Redis::Cache.with do |redis|
        redis_key = "cache:#{described_class.name}:#{agent_token.id}:attributes"
        expect(redis.get(redis_key)).to be_present
      end
    end

    def does_db_update
      expect { subject }.to change { agent_token.reload.read_attribute(:last_used_at) }
    end
  end
end

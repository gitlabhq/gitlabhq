# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Operations::FeatureFlagsClient do
  let_it_be(:project) { create(:project) }

  let!(:client) { create(:operations_feature_flags_client, project: project) }

  subject { client }

  before do
    client.unleash_app_name = 'production'
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#token' do
    # Specify a blank token_encrypted so that the model's method is used
    # instead of the factory value
    subject { create(:operations_feature_flags_client, token_encrypted: nil) }

    it "ensures that token is always set" do
      expect(subject.token).to match(/glffct-[A-Za-z0-9_-]{20}/)
    end
  end

  describe '.update_last_feature_flag_updated_at!' do
    subject { described_class.update_last_feature_flag_updated_at!(project) }

    it 'updates the last_feature_flag_updated_at of the project client' do
      freeze_time do
        expect { subject }.to change { client.reload.last_feature_flag_updated_at }.from(nil).to(Time.current)
      end
    end
  end

  describe '#unleash_api_version' do
    subject { client.unleash_api_version }

    it { is_expected.to eq(described_class::DEFAULT_UNLEASH_API_VERSION) }
  end

  describe '#unleash_api_features' do
    subject { client.unleash_api_features }

    it 'fetches' do
      expect(Operations::FeatureFlag).to receive(:for_unleash_client).with(project, 'production').once

      subject
    end

    context 'when unleash app name is not set' do
      before do
        client.unleash_app_name = nil
      end

      it 'does not fetch' do
        expect(Operations::FeatureFlag).not_to receive(:for_unleash_client)

        subject
      end
    end
  end

  describe '#unleash_api_cache_key' do
    subject { client.unleash_api_cache_key }

    it 'constructs the cache key' do
      is_expected.to eq("api_version:#{client.unleash_api_version}"\
        ":app_name:#{client.unleash_app_name}"\
        ":updated_at:#{client.last_feature_flag_updated_at.to_i}")
    end

    context 'when unleash app name is not set' do
      before do
        client.unleash_app_name = nil
      end

      it 'constructs the cache key without unleash app name' do
        is_expected.to eq("api_version:#{client.unleash_api_version}"\
          ":app_name:"\
          ":updated_at:#{client.last_feature_flag_updated_at.to_i}")
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::SidekiqStatusMigrator, feature_category: :redis do
  let(:instance_specific_config_file) { "config/redis.shared_state.yml" }
  let(:rails_root) { "test" }

  include_examples "multi_store_wrapper_shared_examples"

  it 'migrates data from SharedState to QueuesMetadata' do
    expect(described_class.multistore.primary_pool).to eq(Gitlab::Redis::QueuesMetadata.pool)
    expect(described_class.multistore.secondary_pool).to eq(Gitlab::Redis::SharedState.pool)
  end
end

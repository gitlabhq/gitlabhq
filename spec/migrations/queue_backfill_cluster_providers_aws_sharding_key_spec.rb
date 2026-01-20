# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillClusterProvidersAwsShardingKey, feature_category: :deployment_management do
  let(:migration) { described_class.new }

  describe '#up' do
    it 'queues the batched background migration' do
      expect(migration).to receive(:queue_batched_background_migration).with(
        'BackfillClusterProvidersAwsShardingKey',
        :cluster_providers_aws,
        :id,
        batch_size: 1000,
        sub_batch_size: 100
      )

      migration.up
    end
  end

  describe '#down' do
    it 'deletes the batched background migration' do
      expect(migration).to receive(:delete_batched_background_migration).with(
        'BackfillClusterProvidersAwsShardingKey',
        :cluster_providers_aws,
        :id,
        []
      )

      migration.down
    end
  end
end

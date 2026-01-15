# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TruncatePartition, feature_category: :database do
  let(:partition_name) { 'ci_builds_metadata_100' }
  let(:connection) { Ci::ApplicationRecord.connection }

  let(:allowed_partitions) do
    { ci_builds_metadata_100: { parent_table: 'p_ci_builds_metadata' } }
  end

  let(:partition_data) do
    { 'is_attached' => false, 'target_schema' => 'gitlab_partitions_dynamic', 'target_partition' => partition_name }
  end

  subject(:service) { described_class.new(partition_name) }

  before do
    skip_if_shared_database(:ci)

    allow(Gitlab::Database::Dictionary.entries)
      .to receive(:find_detach_allowed_partitions).and_return(allowed_partitions)
    allow(Gitlab::Database::EachDatabase).to receive(:each_connection).and_yield(connection, 'main')
    allow(Gitlab::TaskHelpers).to receive(:get_partition_info).and_return(partition_data)
  end

  describe '#execute' do
    context 'when partition is not in allowlist' do
      let(:allowed_partitions) { {} }

      it 'returns false' do
        expect(service.execute).to be(false)
      end
    end

    context 'when partition does not exist' do
      let(:partition_data) { nil }

      it 'returns true' do
        expect(service.execute).to be(true)
      end
    end

    context 'when partition is still attached' do
      let(:partition_data) { super().merge('is_attached' => true) }

      it 'returns false' do
        expect(service.execute).to be(false)
      end
    end

    context 'when partition is detached' do
      let(:lock_retries) { instance_double(Gitlab::Database::WithLockRetries) }

      before do
        allow(Gitlab::Database::WithLockRetries).to receive(:new).and_return(lock_retries)
        allow(lock_retries).to receive(:run).and_yield
      end

      it 'truncates the partition' do
        expect(connection).to receive(:execute).with(/TRUNCATE.*#{partition_name}/)

        service.execute
      end

      it 'returns true' do
        allow(connection).to receive(:execute)

        expect(service.execute).to be(true)
      end
    end
  end
end

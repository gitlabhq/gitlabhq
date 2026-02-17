# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AlterPartition, :silence_stdout, feature_category: :database do
  let(:partition_name) { 'ci_builds_metadata_100' }
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:lock_tables) { nil }

  let(:allowed_partitions) do
    {
      ci_builds_metadata_100: {
        parent_table: 'p_ci_builds_metadata',
        parent_schema: 'public',
        bounds_clause: "FOR VALUES IN ('100')",
        required_constraint: '(partition_id = 100)',
        lock_tables: lock_tables
      }
    }
  end

  let(:partition_data) do
    {
      'is_attached' => true,
      'target_schema' => 'gitlab_partitions_dynamic',
      'target_partition' => partition_name,
      'parent_schema' => 'public',
      'parent_table' => 'p_ci_builds_metadata',
      'partition_bounds' => "FOR VALUES IN ('100')",
      'check_constraints' => [{ 'raw_check_clause' => '(partition_id = 100)' }]
    }
  end

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

      subject(:service) { described_class.new(partition_name, :detach) }

      it 'returns false' do
        expect(service.execute).to be(false)
      end
    end

    context 'when partition does not exist' do
      let(:partition_data) { nil }

      subject(:service) { described_class.new(partition_name, :detach) }

      it 'returns false' do
        expect(service.execute).to be(false)
      end
    end

    context 'when detaching' do
      subject(:service) { described_class.new(partition_name, :detach) }

      context 'when partition is already detached' do
        let(:partition_data) { super().merge('is_attached' => false) }

        it 'returns false' do
          expect(service.execute).to be(false)
        end
      end

      context 'when bounds clause does not match' do
        let(:partition_data) { super().merge('partition_bounds' => "FOR VALUES IN ('999')") }

        it 'returns false' do
          expect(service.execute).to be(false)
        end
      end

      context 'when partition is attached with valid bounds' do
        it 'detaches the partition concurrently' do
          allow(service).to receive(:pending_detach?).and_return(false)

          expect(connection).to receive(:execute) do |sql|
            expect(sql).to include('DETACH PARTITION')
            expect(sql).to include(partition_name)
            expect(sql).to include('CONCURRENTLY')
          end

          service.execute
        end

        it 'returns true' do
          allow(connection).to receive(:execute)
          allow(service).to receive(:pending_detach?).and_return(false)

          expect(service.execute).to be(true)
        end
      end

      context 'when partition has pending detach' do
        let(:lock_retries) { instance_double(Gitlab::Database::WithLockRetries) }

        before do
          allow(connection).to receive(:select_value).and_return(true)
          allow(connection).to receive(:execute)
          allow(Gitlab::Database::WithLockRetries).to receive(:new).and_return(lock_retries)
          allow(lock_retries).to receive(:run).and_yield
        end

        it 'finalizes the detach' do
          service.execute

          expect(connection).to have_received(:execute) do |sql|
            expect(sql).to include('DETACH PARTITION', partition_name, 'FINALIZE')
            expect(sql).not_to include('CONCURRENTLY')
          end
        end
      end
    end

    context 'when reattaching' do
      subject(:service) { described_class.new(partition_name, :reattach) }

      let(:partition_data) { super().merge('is_attached' => false) }
      let(:lock_retries) { instance_double(Gitlab::Database::WithLockRetries) }

      before do
        allow(Gitlab::Database::WithLockRetries).to receive(:new).and_return(lock_retries)
        allow(lock_retries).to receive(:run).and_yield
      end

      context 'when partition is already attached' do
        let(:partition_data) { super().merge('is_attached' => true) }

        it 'returns false' do
          expect(service.execute).to be(false)
        end
      end

      context 'when required constraint is missing' do
        let(:partition_data) { super().merge('check_constraints' => []) }

        it 'returns false' do
          expect(service.execute).to be(false)
        end
      end

      context 'when partition is detached with valid constraint' do
        it 'reattaches the partition' do
          expect(connection).to receive(:execute).with(/ATTACH PARTITION.*#{partition_name}/)

          service.execute
        end

        it 'returns true' do
          allow(connection).to receive(:execute)

          expect(service.execute).to be(true)
        end
      end

      context 'when lock_tables is configured' do
        let(:lock_tables) { %w[p_ci_builds p_ci_builds_metadata] }

        it 'locks tables before attaching' do
          expect(connection).to receive(:execute) do |sql|
            expect(sql).to include('LOCK')
            expect(sql).to include('p_ci_builds')
            expect(sql).to include('p_ci_builds_metadata')
            expect(sql).to include('ACCESS EXCLUSIVE MODE')
            expect(sql).to include('ATTACH PARTITION')
          end

          service.execute
        end
      end

      context 'when lock_tables is not configured' do
        let(:lock_tables) { nil }

        it 'does not include lock statements' do
          expect(connection).to receive(:execute) do |sql|
            expect(sql).to include('ATTACH PARTITION')
            expect(sql).not_to include('LOCK TABLE')
          end

          service.execute
        end
      end
    end
  end
end

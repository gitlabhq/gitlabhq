# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::Leases::ReconciliationService, feature_category: :cell do
  let(:cell_id) { 1 }
  let(:mock_claim_service) { instance_double(::Gitlab::TopologyServiceClient::ClaimService) }
  let(:service) { described_class.new }

  before do
    allow(mock_claim_service).to receive(:cell_id).and_return(cell_id)
    allow(Gitlab::TopologyServiceClient::ClaimService).to receive(:instance).and_return(mock_claim_service)
  end

  describe '#execute' do
    context 'when there are no outstanding leases' do
      before do
        stub_list_leases([])
      end

      it 'completes with nothing changed' do
        result = service.execute

        expect(result).to match({
          processed: 0,
          committed: 0,
          rolled_back: 0,
          pending: 0,
          orphaned: 0
        })
      end
    end

    context 'when there are active leases' do
      let(:lease_uuid) { SecureRandom.uuid }
      let(:active_lease) do
        Gitlab::Cells::TopologyService::Claims::V1::LeaseRecord.new(
          uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid),
          created_at: Google::Protobuf::Timestamp.new(seconds: 2.minutes.ago.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: 2.minutes.ago.to_i)
        )
      end

      before do
        stub_list_leases([active_lease])
      end

      context 'when lease exists locally' do
        before do
          create(:cells_outstanding_lease, uuid: lease_uuid)
        end

        it 'does not commit and returns correct counts' do
          expect(mock_claim_service).not_to receive(:commit_update)

          expect(service.execute).to match({
            processed: 1,
            committed: 0,
            rolled_back: 0,
            pending: 0,
            orphaned: 0
          })
        end
      end

      context 'when lease does not exist locally' do
        it 'does not commit and returns correct counts' do
          expect(mock_claim_service).not_to receive(:commit_update)

          expect(service.execute).to match({
            processed: 1,
            committed: 0,
            rolled_back: 0,
            pending: 1,
            orphaned: 0
          })
        end
      end
    end

    context 'when there are stale leases' do
      let(:lease_uuid) { SecureRandom.uuid }
      let(:stale_lease) do
        Gitlab::Cells::TopologyService::Claims::V1::LeaseRecord.new(
          uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid),
          created_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i)
        )
      end

      before do
        stub_list_leases([stale_lease])
      end

      context 'when lease exists locally' do
        before do
          create(:cells_outstanding_lease, uuid: lease_uuid, created_at: 10.minutes.ago, updated_at: 10.minutes.ago)
        end

        it 'commits the lease, destroys the record, and returns correct counts' do
          expected_request = Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
            lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid),
            cell_id: cell_id
          )
          expect(mock_claim_service).to receive(:commit_update).with(expected_request, deadline: anything)

          result = nil
          expect { result = service.execute }.to change { Cells::OutstandingLease.count }.by(-1)
          expect(result).to match({
            processed: 1,
            committed: 1,
            rolled_back: 0,
            pending: 0,
            orphaned: 0
          })
        end
      end

      context 'when lease does not exist locally' do
        it 'rolls back via topology service, logs info, and returns correct counts' do
          expected_request = Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
            lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid),
            cell_id: cell_id
          )

          expect(mock_claim_service).to receive(:rollback_update).with(expected_request, deadline: anything)
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              cell_id: cell_id,
              feature_category: :cell,
              message: 'Rolled back stale lost lease',
              lease_uuid: lease_uuid,
              lease_updated_at: anything,
              staleness_duration: anything
            )
          )

          result = service.execute

          expect(result).to match({
            processed: 1,
            committed: 0,
            rolled_back: 1,
            pending: 0,
            orphaned: 0
          })
        end
      end
    end

    context 'with cursor-based pagination' do
      let(:lease1_uuid) { SecureRandom.uuid }
      let(:lease2_uuid) { SecureRandom.uuid }
      let(:cursor) { Google::Protobuf::Any.new }

      let(:page1_lease) do
        Gitlab::Cells::TopologyService::Claims::V1::LeaseRecord.new(
          uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease1_uuid),
          created_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i)
        )
      end

      let(:page2_lease) do
        Gitlab::Cells::TopologyService::Claims::V1::LeaseRecord.new(
          uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease2_uuid),
          created_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i)
        )
      end

      before do
        Cells::OutstandingLease.create!(uuid: lease1_uuid, created_at: 10.minutes.ago, updated_at: 10.minutes.ago)
        Cells::OutstandingLease.create!(uuid: lease2_uuid, created_at: 10.minutes.ago, updated_at: 10.minutes.ago)
        stub_list_leases([page1_lease], next_cursor: cursor, limit: 100)
        stub_list_leases([page2_lease], next_cursor: nil, cursor: cursor, limit: 100)
      end

      it 'processes all pages and returns correct total counts' do
        expect(mock_claim_service).to receive(:commit_update).twice

        result = service.execute

        expect(result).to match({
          processed: 2,
          committed: 2,
          rolled_back: 0,
          pending: 0,
          orphaned: 0
        })
      end
    end

    context 'when commit fails' do
      let(:lease_uuid) { SecureRandom.uuid }
      let(:active_lease) do
        Gitlab::Cells::TopologyService::Claims::V1::LeaseRecord.new(
          uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid),
          created_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: 10.minutes.ago.to_i)
        )
      end

      before do
        create(:cells_outstanding_lease, uuid: lease_uuid, created_at: 10.minutes.ago, updated_at: 10.minutes.ago)
        stub_list_leases([active_lease])
        allow(mock_claim_service).to receive(:commit_update).and_raise(StandardError.new('Commit failed'))
      end

      it 'tracks the exception and returns zero committed leases' do
        expect(mock_claim_service).to receive(:commit_update).and_raise(StandardError.new('Commit failed'))
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(StandardError), hash_including(lease_uuid: lease_uuid))

        result = service.execute

        expect(result).to match({
          processed: 1,
          committed: 0,
          rolled_back: 0,
          pending: 0,
          orphaned: 0
        })
      end
    end

    context 'for cleanup_orphaned_leases' do
      let(:old_lease_uuid) { SecureRandom.uuid }
      let!(:old_lease) do
        create(:cells_outstanding_lease, uuid: old_lease_uuid, created_at: 61.minutes.ago, updated_at: 61.minutes.ago)
      end

      let(:recent_lease_uuid) { SecureRandom.uuid }
      let!(:recent_lease) { create(:cells_outstanding_lease, uuid: recent_lease_uuid) }

      let(:remote_lease_uuid) { SecureRandom.uuid }
      let!(:remote_lease) { create(:cells_outstanding_lease, uuid: remote_lease_uuid) }

      let(:active_lease) do
        Gitlab::Cells::TopologyService::Claims::V1::LeaseRecord.new(
          uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: remote_lease_uuid),
          created_at: Google::Protobuf::Timestamp.new(seconds: 1.minute.ago.to_i),
          updated_at: Google::Protobuf::Timestamp.new(seconds: 1.minute.ago.to_i)
        )
      end

      before do
        stub_list_leases([active_lease])
        allow(mock_claim_service).to receive(:commit_update)
      end

      it 'logs more info about the lease' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Cleaned up orphaned leases (stale locally, missing remotely)',
            lease_uuids: [old_lease_uuid],
            cell_id: cell_id,
            feature_category: :cell,
            deleted_count: 1,
            cutoff_time: anything)
        )

        service.execute
      end

      it 'destroys old orphaned leases' do
        expect { service.execute }.to change { Cells::OutstandingLease.by_uuid(old_lease_uuid).count }.from(1).to(0)
      end

      it 'does not touch recent leases' do
        expect { service.execute }.not_to change { Cells::OutstandingLease.by_uuid(recent_lease_uuid).count }
      end

      it 'does not touch remote leases' do
        allow(Cells::OutstandingLease).to receive(:delete).and_return(2)

        expect { service.execute }.not_to change { Cells::OutstandingLease.by_uuid(remote_lease_uuid).count }
      end

      it 'does not call rollback_update for orphaned leases' do
        expect(mock_claim_service).not_to receive(:rollback_update)

        service.execute
      end
    end
  end

  def stub_list_leases(leases, next_cursor: nil, cursor: nil, limit: 100)
    response = Gitlab::Cells::TopologyService::Claims::V1::ListLeasesResponse.new(
      leases: leases,
      next: next_cursor
    )

    expect(mock_claim_service).to receive(:list_leases).with(cursor: cursor, deadline: anything,
      limit: limit).and_return(response)
  end
end

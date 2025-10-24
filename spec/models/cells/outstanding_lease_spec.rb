# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::OutstandingLease, feature_category: :cell do
  let(:cell_id) { 1 }
  let(:uuid_value) { SecureRandom.uuid }
  let(:mock_service) { instance_double(::Gitlab::TopologyServiceClient::ClaimService) }

  before do
    allow(described_class).to receive(:claim_service).and_return(mock_service)
    allow(mock_service).to receive(:cell_id).and_return(cell_id)
  end

  describe '.create_from_request!' do
    let(:create_records) { [{}] }
    let(:destroy_records) { [{}] }

    let(:mock_response) do
      Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid_value)
      )
    end

    it 'calls begin_update and creates an OutstandingLease' do
      expected_request = Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
        create_records: create_records,
        destroy_records: destroy_records,
        cell_id: cell_id
      )

      expect(mock_service)
        .to receive(:begin_update).with(expected_request, deadline: nil).and_return(mock_response)

      lease = described_class.create_from_request!(create_records: create_records, destroy_records: destroy_records)

      expect(lease).to be_persisted
      expect(lease.uuid).to eq(uuid_value)
    end

    context 'with deadline' do
      let(:deadline) { GRPC::Core::TimeConsts.from_relative_time(5.0) }

      it 'calls begin_update with deadline and creates an OutstandingLease' do
        expected_request = Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
          create_records: create_records,
          destroy_records: destroy_records,
          cell_id: cell_id
        )

        expect(mock_service)
          .to receive(:begin_update).with(expected_request, deadline: deadline).and_return(mock_response)

        lease = described_class.create_from_request!(
          create_records: create_records,
          destroy_records: destroy_records,
          deadline: deadline
        )

        expect(lease).to be_persisted
        expect(lease.uuid).to eq(uuid_value)
      end
    end
  end

  describe '#send_commit_update!' do
    let(:lease) { described_class.create!(uuid: uuid_value) }

    it 'sends a commit_update request with the correct parameters' do
      expected_request = Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
        lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid_value),
        cell_id: cell_id
      )

      expect(mock_service).to receive(:commit_update).with(expected_request, deadline: nil)

      lease.send_commit_update!
    end

    context 'with deadline' do
      let(:deadline) { GRPC::Core::TimeConsts.from_relative_time(5.0) }

      it 'sends a commit_update request with the correct parameters' do
        expected_request = Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
          lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid_value),
          cell_id: cell_id
        )

        expect(mock_service).to receive(:commit_update).with(expected_request, deadline: deadline)

        lease.send_commit_update!(deadline: deadline)
      end
    end
  end

  describe '#send_rollback_update!' do
    context 'when uuid is present' do
      let(:lease) { described_class.create!(uuid: uuid_value) }

      it 'sends a rollback_update request with the correct parameters' do
        expected_request = Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
          lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid_value),
          cell_id: cell_id
        )

        expect(mock_service).to receive(:rollback_update).with(expected_request, deadline: nil)

        lease.send_rollback_update!
      end

      context 'with deadline' do
        let(:deadline) { GRPC::Core::TimeConsts.from_relative_time(5.0) }

        it 'sends a rollback_update request with the correct parameters' do
          expected_request = Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
            lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid_value),
            cell_id: cell_id
          )

          expect(mock_service).to receive(:rollback_update).with(expected_request, deadline: deadline)

          lease.send_rollback_update!(deadline: deadline)
        end
      end
    end

    context 'when uuid is nil' do
      let(:lease) { described_class.new(uuid: nil) }

      it 'does not send a rollback_update request' do
        expect(mock_service).not_to receive(:rollback_update)

        lease.send_rollback_update!
      end
    end
  end

  describe '.claim_service' do
    it 'returns the ClaimService instance' do
      expect(described_class.claim_service).to eq(mock_service)
    end
  end
end

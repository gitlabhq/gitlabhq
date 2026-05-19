# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::Claims::BulkClaimService, feature_category: :cell do
  let(:mock_claim_service) { instance_double(::Gitlab::TopologyServiceClient::ClaimService) }
  let(:lease_uuid) { SecureRandom.uuid }
  let(:fake_deadline) { 'fake-deadline' }
  let(:begin_update_response) do
    Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new(
      lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: lease_uuid)
    )
  end

  before do
    stub_config_cell(enabled: true)
    allow(Gitlab::TopologyServiceClient::ClaimService).to receive(:instance).and_return(mock_claim_service)
    allow(mock_claim_service).to receive(:cell_id).and_return(1)
    allow(GRPC::Core::TimeConsts).to receive(:from_relative_time).and_return(fake_deadline)
  end

  describe '#execute' do
    context 'when model is not claimable' do
      let(:non_claimable_model) do
        Class.new(ApplicationRecord) do
          self.table_name = 'foobar'
          def self.name = 'FooBar'
        end
      end

      let(:service) do
        described_class.new(model: non_claimable_model, attribute: :path, creates: [])
      end

      it 'returns zero creates' do
        expect(service.execute).to include(created: 0, chunk_count: 0)
      end

      it 'logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(message: /FooBar model is not claimable/)
        )

        service.execute
      end
    end

    context 'when creates are empty' do
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, creates: [])
      end

      it 'returns zero creates' do
        expect(service.execute).to include(created: 0, chunk_count: 0)
      end

      it 'does not call begin_update' do
        expect(mock_claim_service).not_to receive(:begin_update)
        service.execute
      end
    end

    context 'when create metadata exists' do
      let(:create_metadata) do
        [{
          bucket: {
            type: Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
            value: 'old-group-path'
          },
          subject: {
            type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
            id: 42
          },
          source: {
            type: RedirectRoute.cells_claims_source_type,
            rails_primary_key_id: Cells::Serialization.to_bytes(1)
          }
        }]
      end

      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, creates: create_metadata)
      end

      before do
        stub_commit
      end

      it 'creates claims for the records' do
        expect(mock_claim_service).to receive(:begin_update).with(
          hash_including(create_records: be_present, destroy_records: [])
        ).and_return(begin_update_response)

        service.execute
      end

      it 'commits the update' do
        expect(mock_claim_service).to receive(:commit_update).with(lease_uuid, deadline: fake_deadline)
        service.execute
      end

      it 'returns the correct create count' do
        result = service.execute
        expect(result[:created]).to eq(1)
        expect(result[:chunk_count]).to eq(1)
      end

      it 'logs batch progress' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: "Cells::Claims::BulkClaimService batch processed",
            table_name: 'redirect_routes',
            created: 1,
            chunk_count: 1
          )
        )

        service.execute
      end
    end

    context 'when multiple create metadata entries exist' do
      let(:create_metadata) do
        [
          {
            bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
              value: 'old-path/sub1'
            },
            subject: {
              type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
              id: 42
            },
            source: {
              type: RedirectRoute.cells_claims_source_type,
              rails_primary_key_id: Cells::Serialization.to_bytes(1)
            }
          },
          {
            bucket: {
              type: Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
              value: 'old-path/sub2'
            },
            subject: {
              type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
              id: 43
            },
            source: {
              type: RedirectRoute.cells_claims_source_type,
              rails_primary_key_id: Cells::Serialization.to_bytes(2)
            }
          }
        ]
      end

      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, creates: create_metadata)
      end

      before do
        stub_commit
      end

      it 'creates claims for all records' do
        result = service.execute
        expect(result[:created]).to eq(2)
      end
    end

    context 'with destroys only' do
      let(:destroy_metadata) do
        [{
          bucket: {
            type: Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
            value: 'old-path'
          },
          subject: {
            type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
            id: 42
          },
          source: {
            type: RedirectRoute.cells_claims_source_type,
            rails_primary_key_id: Cells::Serialization.to_bytes(99)
          }
        }]
      end

      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, destroys: destroy_metadata)
      end

      before do
        stub_commit
      end

      it 'passes destroys to commit_changes' do
        expect(mock_claim_service).to receive(:begin_update).with(
          hash_including(create_records: [], destroy_records: be_present)
        ).and_return(begin_update_response)

        service.execute
      end

      it 'returns the correct destroyed count' do
        result = service.execute
        expect(result[:created]).to eq(0)
        expect(result[:destroyed]).to eq(1)
        expect(result[:chunk_count]).to eq(1)
      end
    end

    context 'with both creates and destroys' do
      let(:create_metadata) do
        [{
          bucket: {
            type: Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
            value: 'new-path'
          },
          subject: {
            type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
            id: 42
          },
          source: {
            type: RedirectRoute.cells_claims_source_type,
            rails_primary_key_id: Cells::Serialization.to_bytes(1)
          }
        }]
      end

      let(:destroy_metadata) do
        [{
          bucket: {
            type: Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
            value: 'old-path'
          },
          subject: {
            type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
            id: 42
          },
          source: {
            type: RedirectRoute.cells_claims_source_type,
            rails_primary_key_id: Cells::Serialization.to_bytes(999)
          }
        }]
      end

      let(:service) do
        described_class.new(
          model: RedirectRoute,
          attribute: :path,
          creates: create_metadata,
          destroys: destroy_metadata
        )
      end

      before do
        stub_commit
      end

      it 'passes both creates and destroys' do
        expect(mock_claim_service).to receive(:begin_update).with(
          hash_including(create_records: be_present, destroy_records: be_present)
        ).and_return(begin_update_response)

        service.execute
      end

      it 'returns correct counts' do
        result = service.execute
        expect(result[:created]).to eq(1)
        expect(result[:destroyed]).to eq(1)
        expect(result[:chunk_count]).to eq(1)
      end
    end

    context 'when destroys are empty and creates are empty' do
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, creates: [], destroys: [])
      end

      it 'returns zeroes' do
        expect(service.execute).to include(created: 0, destroyed: 0, chunk_count: 0)
      end

      it 'does not call begin_update' do
        expect(mock_claim_service).not_to receive(:begin_update)
        service.execute
      end
    end
  end

  def stub_commit(begin_update_response: self.begin_update_response)
    allow(mock_claim_service).to receive(:begin_update).and_return(begin_update_response)
    allow(mock_claim_service).to receive(:commit_update)
  end
end

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
        described_class.new(model: non_claimable_model, attribute: :path, records: [])
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

    context 'when cell config is disabled' do
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, records: RedirectRoute.none)
      end

      before do
        stub_config_cell(enabled: false)
      end

      it 'returns zero creates' do
        expect(service.execute).to include(created: 0, chunk_count: 0)
      end
    end

    context 'when attribute is not configured in cells_claims_attributes' do
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :nonexistent_attr, records: RedirectRoute.none)
      end

      it 'returns zero creates' do
        expect(service.execute).to include(created: 0, chunk_count: 0)
      end
    end

    context 'when feature flag for the attribute is disabled' do
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, records: RedirectRoute.none)
      end

      before do
        stub_feature_flags(cells_claims_routes: false)
      end

      it 'returns zero creates' do
        expect(service.execute).to include(created: 0, chunk_count: 0)
      end
    end

    context 'when attribute has no feature flag configured' do
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, records: RedirectRoute.none)
      end

      before do
        original_config = RedirectRoute.cells_claims_attributes[:path]
        allow(RedirectRoute).to receive(:cells_claims_attributes).and_return(
          { path: original_config.merge(feature_flag: nil) }
        )
      end

      it 'treats the attribute as enabled without checking feature flag' do
        expect(Feature).not_to receive(:enabled?)

        service.execute
      end
    end

    context 'when records are empty' do
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, records: RedirectRoute.none)
      end

      it 'returns zero creates' do
        expect(service.execute).to include(created: 0, chunk_count: 0)
      end

      it 'does not call begin_update' do
        expect(mock_claim_service).not_to receive(:begin_update)
        service.execute
      end
    end

    context 'when a record has no matching claim metadata' do
      let_it_be(:group) { create(:group) }
      let_it_be(:redirect_route) { create(:redirect_route, source: group, path: 'old-group-path') }

      let(:records) { RedirectRoute.where(id: redirect_route.id) }
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, records: records)
      end

      before do
        allow_any_instance_of(RedirectRoute).to receive(:cells_claims_metadata_for_attribute).and_return(nil) # rubocop:disable RSpec/AnyInstanceOf -- need to stub instance method on loaded records
      end

      it 'returns zero creates when all records are skipped' do
        expect(service.execute).to include(created: 0, chunk_count: 0)
      end
    end

    context 'when records exist' do
      let_it_be(:group) { create(:group) }
      let_it_be(:redirect_route) { create(:redirect_route, source: group, path: 'old-group-path') }

      let(:records) { RedirectRoute.where(id: redirect_route.id) }
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, records: records)
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

    context 'when multiple records exist' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup1) { create(:group, parent: group) }
      let_it_be(:subgroup2) { create(:group, parent: group) }
      let_it_be(:redirect_route1) { create(:redirect_route, source: subgroup1, path: 'old-path/sub1') }
      let_it_be(:redirect_route2) { create(:redirect_route, source: subgroup2, path: 'old-path/sub2') }

      let(:records) { RedirectRoute.where(id: [redirect_route1.id, redirect_route2.id]) }
      let(:service) do
        described_class.new(model: RedirectRoute, attribute: :path, records: records)
      end

      before do
        stub_commit
      end

      it 'creates claims for all records' do
        result = service.execute
        expect(result[:created]).to eq(2)
      end
    end
  end

  def stub_commit(begin_update_response: self.begin_update_response)
    allow(mock_claim_service).to receive(:begin_update).and_return(begin_update_response)
    allow(mock_claim_service).to receive(:commit_update)
  end
end

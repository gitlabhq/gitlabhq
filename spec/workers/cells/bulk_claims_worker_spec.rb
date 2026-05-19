# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::BulkClaimsWorker, feature_category: :cell do
  let(:worker) { described_class.new }
  let(:mock_service) { instance_double(Cells::Claims::BulkClaimService) }
  let(:service_result) { { created: 0, destroyed: 0, chunk_count: 0 } }

  before do
    stub_config_cell(enabled: true)
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { ['RedirectRoute', 'path', { 'create_record_ids' => [] }] }
  end

  describe '#perform' do
    context 'when model_name is invalid' do
      it 'returns early for unknown model' do
        expect(Cells::Claims::BulkClaimService).not_to receive(:new)

        worker.perform('NonExistentModel', 'path', {})
      end
    end

    context 'when model is not claimable' do
      it 'returns early' do
        expect(Cells::Claims::BulkClaimService).not_to receive(:new)

        worker.perform('ApplicationRecord', 'path', {})
      end
    end

    context 'when cell config is disabled' do
      before do
        stub_config_cell(enabled: false)
      end

      it 'returns early' do
        expect(Cells::Claims::BulkClaimService).not_to receive(:new)

        worker.perform('RedirectRoute', 'path', {})
      end
    end

    context 'when attribute is not configured for claims' do
      it 'returns early' do
        expect(Cells::Claims::BulkClaimService).not_to receive(:new)

        worker.perform('RedirectRoute', 'unknown_attr', {})
      end
    end

    context 'when feature flag for attribute is disabled' do
      before do
        stub_feature_flags(cells_claims_routes: false)
      end

      it 'returns early' do
        expect(Cells::Claims::BulkClaimService).not_to receive(:new)

        worker.perform('RedirectRoute', 'path', {})
      end
    end

    context 'with create_record_ids' do
      let_it_be(:group) { create(:group) }
      let_it_be(:redirect_route) { create(:redirect_route, source: group, path: 'test-path') }

      it 'loads records, builds metadata, and passes to BulkClaimService' do
        expect(Cells::Claims::BulkClaimService).to receive(:new) do |args|
          expect(args[:model]).to eq(RedirectRoute)
          expect(args[:attribute]).to eq(:path)
          expect(args[:creates].size).to eq(1)
          expect(args[:destroys]).to eq([])

          create_entry = args[:creates].first
          expect(create_entry[:bucket][:type]).to eq(Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES)
          expect(create_entry[:bucket][:value]).to eq('test-path')

          mock_service
        end
        expect(mock_service).to receive(:execute).and_return(service_result)

        worker.perform('RedirectRoute', 'path', { 'create_record_ids' => [redirect_route.id] })
      end

      it 'handles missing records gracefully' do
        expect(Cells::Claims::BulkClaimService).not_to receive(:new)

        worker.perform('RedirectRoute', 'path', { 'create_record_ids' => [-1] })
      end
    end

    context 'with destroy_metadata' do
      let(:destroy_metadata) do
        [{
          'bucket_type' => Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
          'bucket_value' => 'old-path',
          'subject_type' => Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
          'subject_id' => 42,
          'source_type' => RedirectRoute.cells_claims_source_type,
          'primary_key' => 99
        }]
      end

      it 'reconstructs metadata and passes to BulkClaimService' do
        expect(Cells::Claims::BulkClaimService).to receive(:new) do |args|
          expect(args[:model]).to eq(RedirectRoute)
          expect(args[:attribute]).to eq(:path)
          expect(args[:creates]).to eq([])
          expect(args[:destroys].size).to eq(1)

          destroy = args[:destroys].first
          expect(destroy[:bucket][:type]).to eq(Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES)
          expect(destroy[:bucket][:value]).to eq('old-path')
          expect(destroy[:subject][:type]).to eq(Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE)
          expect(destroy[:subject][:id]).to eq(42)
          expect(destroy[:source][:type]).to eq(RedirectRoute.cells_claims_source_type)
          expect(destroy[:source][:rails_primary_key_id]).to eq(Cells::Serialization.to_bytes(99))

          mock_service
        end
        expect(mock_service).to receive(:execute).and_return(service_result)

        worker.perform('RedirectRoute', 'path', { 'destroy_metadata' => destroy_metadata })
      end
    end

    context 'with both creates and destroys' do
      let_it_be(:group) { create(:group) }
      let_it_be(:redirect_route) { create(:redirect_route, source: group, path: 'new-path') }

      let(:destroy_metadata) do
        [{
          'bucket_type' => Cells::Claimable::CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES,
          'bucket_value' => 'old-path',
          'subject_type' => Cells::Claimable::CLAIMS_SUBJECT_TYPE::NAMESPACE,
          'subject_id' => group.id,
          'source_type' => RedirectRoute.cells_claims_source_type,
          'primary_key' => 999
        }]
      end

      it 'passes both to BulkClaimService' do
        expect(Cells::Claims::BulkClaimService).to receive(:new) do |args|
          expect(args[:creates].size).to eq(1)
          expect(args[:destroys].size).to eq(1)
          mock_service
        end
        expect(mock_service).to receive(:execute).and_return(service_result)

        worker.perform('RedirectRoute', 'path', {
          'create_record_ids' => [redirect_route.id],
          'destroy_metadata' => destroy_metadata
        })
      end
    end

    context 'when an error occurs' do
      let_it_be(:group) { create(:group) }
      let_it_be(:redirect_route) { create(:redirect_route, source: group, path: 'error-path') }

      it 'tracks the exception and re-raises' do
        expect(Cells::Claims::BulkClaimService).to receive(:new).and_raise(StandardError, 'test error')
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(StandardError),
          hash_including(feature_category: :cell, model: 'RedirectRoute', attribute: 'path')
        )

        expect do
          worker.perform('RedirectRoute', 'path', { 'create_record_ids' => [redirect_route.id] })
        end.to raise_error(StandardError, 'test error')
      end
    end

    context 'with empty payload' do
      it 'returns early without calling BulkClaimService' do
        expect(Cells::Claims::BulkClaimService).not_to receive(:new)

        worker.perform('RedirectRoute', 'path', {})
      end
    end
  end
end

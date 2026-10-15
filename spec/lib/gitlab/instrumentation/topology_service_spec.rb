# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::TopologyService, feature_category: :cell do
  let(:record_metadata) { Gitlab::Cells::TopologyService::Claims::V1::Metadata.new }
  let(:get_cell_request) { Gitlab::Cells::TopologyService::GetCellRequest.new }
  let(:begin_update_request) do
    Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
      create_records: [record_metadata, record_metadata],
      destroy_records: [record_metadata]
    )
  end

  describe '.payload', :request_store do
    subject(:payload) { described_class.payload }

    context 'when no call was recorded' do
      it { is_expected.to eq({}) }
    end

    context 'when only calls other than BeginUpdate were recorded' do
      before do
        described_class.add_call(request: get_cell_request, duration: 0.1)
        described_class.add_call(request: get_cell_request, duration: 0.25)
      end

      it { is_expected.to eq(topology_service_calls: 2, topology_service_duration_s: 0.35) }
    end

    context 'when BeginUpdate calls were recorded' do
      before do
        described_class.add_call(request: begin_update_request, duration: 0.2)
        described_class.add_call(
          request: Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
            create_records: [record_metadata]
          ),
          duration: 0.3
        )
        described_class.add_call(request: get_cell_request, duration: 0.05)
      end

      it 'adds the BeginUpdate calls, duration, and create and destroy records to the totals' do
        expect(payload).to eq(
          topology_service_calls: 3,
          topology_service_duration_s: 0.55,
          topology_service_begin_update_calls: 2,
          topology_service_begin_update_duration_s: 0.5,
          topology_service_begin_update_create_records: 3,
          topology_service_begin_update_destroy_records: 1
        )
      end
    end
  end

  describe '.add_call' do
    context 'when the request store is not active' do
      it 'does not record the call' do
        allow(Gitlab::SafeRequestStore).to receive(:[]=).and_call_original

        described_class.add_call(request: begin_update_request, duration: 0.1)

        expect(Gitlab::SafeRequestStore).not_to have_received(:[]=).with(described_class::CALL_COUNT, anything)
      end
    end
  end
end

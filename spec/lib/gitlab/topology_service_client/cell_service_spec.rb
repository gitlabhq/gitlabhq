# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::CellService, feature_category: :cell do
  subject(:cell_service) { described_class.new }

  let(:service_class) { Gitlab::Cells::TopologyService::CellService::Stub }
  let(:cell_id) { 1 }
  let(:request) { Gitlab::Cells::TopologyService::GetCellRequest.new(cell_id: cell_id) }
  let(:sequence_ranges) { [Gitlab::Cells::TopologyService::SequenceRange.new(minval: 1, maxval: 1000)] }

  let(:cell_info) do
    Gitlab::Cells::TopologyService::CellInfo.new(
      id: cell_id,
      address: "127.0.0.1:3000",
      session_prefix: "cell-1-",
      sequence_ranges: sequence_ranges
    )
  end

  shared_context 'with cell enabled' do
    before do
      allow(Gitlab.config.cell).to receive_messages(id: cell_id, enabled: true)
    end
  end

  describe '#get_cell_info' do
    context 'when topology service is disabled' do
      before do
        allow(Gitlab.config.cell).to receive(:enabled).and_return(false)
      end

      it 'raises NotImplementedError' do
        expect { cell_service }.to raise_error(NotImplementedError)
      end
    end

    context 'when cell is enabled' do
      include_context 'with cell enabled'

      context 'when cell exists' do
        before do
          allow_next_instance_of(service_class) do |instance|
            allow(instance).to receive(:get_cell)
              .with(request).and_return(Gitlab::Cells::TopologyService::GetCellResponse.new(cell_info: cell_info))
          end
        end

        it 'returns cell info' do
          expect(cell_service.get_cell_info).to eq(cell_info)
        end
      end

      context 'when cell is not found' do
        before do
          allow_next_instance_of(service_class) do |instance|
            allow(instance).to receive(:get_cell).with(request).and_raise(GRPC::NotFound)
          end
        end

        it 'logs and raises CellNotFoundError' do
          expect(Gitlab::AppLogger).to receive(:error)
            .with(hash_including(message: "Cell '#{cell_id}' not found on Topology Service"))

          expect { cell_service.get_cell_info }
            .to raise_error(Gitlab::TopologyServiceClient::CellNotFoundError)
        end
      end
    end
  end

  describe '#cell_sequence_ranges' do
    include_context 'with cell enabled'

    context 'when cell exists' do
      before do
        allow(cell_service).to receive(:get_cell_info).and_return(cell_info)
      end

      it 'returns sequence ranges' do
        expect(cell_service.cell_sequence_ranges).to match_array(sequence_ranges)
      end
    end

    context 'when cell is not found' do
      before do
        allow_next_instance_of(service_class) do |instance|
          allow(instance).to receive(:get_cell).with(request).and_raise(GRPC::NotFound)
        end
      end

      it 'raises CellNotFoundError' do
        expect { cell_service.cell_sequence_ranges }
          .to raise_error(Gitlab::TopologyServiceClient::CellNotFoundError)
      end
    end
  end
end

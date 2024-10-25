# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::CellService, feature_category: :cell do
  subject(:cell_service) { described_class.new }
  let(:service_class) { Gitlab::Cells::TopologyService::CellService::Stub } # gRpc Service Class

  describe '#get_cell_info' do
    context 'when topology service is disabled' do
      it 'raises an error when topology service is not enabled' do
        expect(Gitlab.config.topology_service).to receive(:enabled).and_return(false)

        expect { cell_service }.to raise_error(NotImplementedError)
      end

      it 'raises an error when no cell is configured' do
        allow(Gitlab.config.topology_service).to receive(:enabled).and_return(true)
        expect(Gitlab.config.cell).to receive(:name).once.and_return(nil)

        expect { cell_service }.to raise_error(NotImplementedError)
      end
    end

    context 'when topology service is enabled' do
      before do
        allow(Gitlab.config.topology_service).to receive(:enabled).once.and_return(true)
        allow(Gitlab.config.cell).to receive(:name).once.and_return("cell-1")
      end

      let(:cell_info) do
        Gitlab::Cells::TopologyService::CellInfo.new(
          name: "cell-1",
          address: "127.0.0.1:3000",
          session_prefix: "cell-1-",
          sequence_range: Gitlab::Cells::TopologyService::SequenceRange.new(minval: 1, maxval: 1000)
        )
      end

      it 'returns the cell information' do
        expect_next_instance_of(service_class) do |instance|
          expect(instance).to receive(:get_cell).with(
            Gitlab::Cells::TopologyService::GetCellRequest.new(cell_name: "cell-1")
          ).and_return(Gitlab::Cells::TopologyService::GetCellResponse.new(cell_info: cell_info))
        end

        expect(cell_service.get_cell_info).to eq(cell_info)
      end

      it 'returns nil if the cell is not found' do
        expect_next_instance_of(service_class) do |instance|
          expect(instance).to receive(:get_cell).with(
            Gitlab::Cells::TopologyService::GetCellRequest.new(cell_name: "cell-1")
          ).and_raise(GRPC::NotFound)
        end

        expected_error = "Cell 'cell-1' not found on Topology Service"
        expect(Gitlab::AppLogger).to receive(:error).with(hash_including(message: expected_error))
        expect(cell_service.get_cell_info).to be_nil
      end
    end
  end
end

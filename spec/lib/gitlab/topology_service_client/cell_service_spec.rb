# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::CellService, feature_category: :cell do
  subject(:cell_service) { described_class.new }
  let(:service_class) { Gitlab::Cells::TopologyService::CellService::Stub } # gRpc Service Class

  let(:cell_info) do
    Gitlab::Cells::TopologyService::CellInfo.new(
      name: "cell-1",
      address: "127.0.0.1:3000",
      session_prefix: "cell-1-",
      sequence_range: Gitlab::Cells::TopologyService::SequenceRange.new(minval: 1, maxval: 1000)
    )
  end

  describe '#get_cell_info' do
    context 'when topology service is disabled' do
      it 'raises an error when topology service is not enabled' do
        expect(Gitlab.config.cell.topology_service).to receive(:enabled).and_return(false)

        expect { cell_service }.to raise_error(NotImplementedError)
      end
    end

    context 'when topology service is enabled' do
      before do
        allow(Gitlab.config.cell).to receive(:id).twice.and_return(1)
        allow(Gitlab.config.cell.topology_service).to receive(:enabled).once.and_return(true)
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

  describe '#cell_sequence_range' do
    context 'when topology service is enabled' do
      before do
        allow(Gitlab.config.cell).to receive(:id).twice.and_return(1)
        allow(Gitlab.config.cell.topology_service).to receive(:enabled).once.and_return(true)
      end

      context 'when a cell exists in topology service' do
        before do
          allow_next_instance_of(service_class) do |instance|
            allow(instance).to receive(:get_cell).and_return(
              Gitlab::Cells::TopologyService::GetCellResponse.new(cell_info: cell_info)
            )
          end
        end

        it { expect(cell_service.cell_sequence_range).to match_array([1, 1000]) }
      end

      context 'when a cell is not found in topology service' do
        before do
          allow_next_instance_of(service_class) do |instance|
            allow(instance).to receive(:get_cell).and_raise(GRPC::NotFound)
          end
        end

        it { expect(cell_service.cell_sequence_range).to be_nil }
      end
    end
  end
end

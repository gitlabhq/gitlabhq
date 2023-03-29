# frozen_string_literal: true

RSpec.shared_examples 'Data transfer resolver' do
  it 'returns mock data' do |_query_object|
    mocked_data = ['mocked_data']

    allow_next_instance_of(DataTransfer::MockedTransferFinder) do |instance|
      allow(instance).to receive(:execute).and_return(mocked_data)
    end

    expect(resolve_egress[:egress_nodes]).to eq(mocked_data)
  end

  context 'when data_transfer_monitoring is disabled' do
    before do
      stub_feature_flags(data_transfer_monitoring: false)
    end

    it 'returns empty result' do
      expect(resolve_egress).to eq(egress_nodes: [])
    end
  end
end

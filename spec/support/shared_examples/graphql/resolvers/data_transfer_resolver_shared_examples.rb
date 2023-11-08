# frozen_string_literal: true

RSpec.shared_examples 'Data transfer resolver' do
  context 'when data_transfer_monitoring is disabled' do
    before do
      stub_feature_flags(data_transfer_monitoring: false)
    end

    it 'returns empty result' do
      expect(resolve_egress).to eq(egress_nodes: [])
    end
  end
end

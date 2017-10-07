require 'spec_helper'

describe ClusterEntity do
  set(:cluster) { create(:gcp_cluster, :errored) }
  let(:request) { double('request') }

  let(:entity) do
    described_class.new(cluster)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains status' do
      expect(subject[:status]).to eq(:errored)
    end

    it 'contains status reason' do
      expect(subject[:status_reason]).to eq('general error')
    end
  end
end

require 'spec_helper'

describe ClusterSerializer do
  let(:serializer) do
    described_class.new
  end

  describe '#represent_status' do
    subject { serializer.represent_status(resource) }

    context 'when represents only status' do
      let(:resource) { create(:gcp_cluster, :errored) }

      it 'serializes only status' do
        expect(subject.keys).to contain_exactly(:status, :status_reason)
      end
    end
  end
end

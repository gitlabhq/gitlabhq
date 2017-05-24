require 'spec_helper'

describe Gitlab::Geo::JwtRequestDecoder do
  let!(:primary_node) { FactoryGirl.create(:geo_node, :primary) }
  let(:data) { { input: 123 } }
  let(:request) { Gitlab::Geo::TransferRequest.new(data) }

  subject { described_class.new(request.headers['Authorization']) }

  describe '#decode' do
    it 'decodes correct data' do
      expect(subject.decode).to eq(data)
    end

    it 'fails to decode when node is disabled' do
      primary_node.enabled = false
      primary_node.save

      expect(subject.decode).to be_nil
    end

    it 'fails to decode with wrong key' do
      data = request.headers['Authorization']

      primary_node.secret_access_key = ''
      primary_node.save
      expect(described_class.new(data).decode).to be_nil
    end

    it 'returns nil when clocks are not in sync' do
      allow(JWT).to receive(:decode).and_raise(JWT::InvalidIatError)

      expect(subject.decode).to be_nil
    end
  end
end

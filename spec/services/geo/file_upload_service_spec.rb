require 'spec_helper'

describe Geo::FileUploadService, services: true do
  let(:lfs_object) { create(:lfs_object, :with_file) }
  let(:params) { { id: lfs_object.id, type: 'lfs' } }
  let(:lfs_transfer) { Gitlab::Geo::LfsTransfer.new(lfs_object) }
  let(:transfer_request) { Gitlab::Geo::TransferRequest.new(lfs_transfer.request_data) }
  let(:req_header) { transfer_request.header['Authorization'] }

  before do
    create(:geo_node, :current)
  end

  describe '#execute' do
    it 'sends LFS file' do
      service = described_class.new(params, req_header)

      response = service.execute

      expect(response[:code]).to eq(:ok)
      expect(response[:file].file.path).to eq(lfs_object.file.path)
    end

    it 'returns nil if no authorization' do
      service = described_class.new(params, nil)

      expect(service.execute).to be_nil
    end
  end
end

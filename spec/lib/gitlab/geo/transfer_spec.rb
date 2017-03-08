require 'spec_helper'

describe Gitlab::Geo::Transfer do
  let!(:primary_node) { FactoryGirl.create(:geo_node, :primary) }
  let!(:secondary_node) { FactoryGirl.create(:geo_node) }
  let(:lfs_object) { create(:lfs_object, :with_file) }
  let(:url) { primary_node.geo_transfers_url(:lfs, lfs_object.id.to_s) }
  let(:content) { StringIO.new("1\n2\n3") }
  let(:size) { File.stat(lfs_object.file.path).size }

  before do
    allow(File).to receive(:open).with(lfs_object.file.path, "wb").and_yield(content)
  end

  subject do
    described_class.new(:lfs,
                        lfs_object.id,
                        lfs_object.file.path,
                        { sha256: lfs_object.oid })
  end

  it '#download_from_primary' do
    allow(Gitlab::Geo).to receive(:current_node) { secondary_node }
    response = double(success?: true)
    expect(HTTParty).to receive(:get).and_return(response)

    expect(subject.download_from_primary).to eq(size)
  end
end

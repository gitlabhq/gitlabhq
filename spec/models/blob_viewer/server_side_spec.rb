require 'spec_helper'

describe BlobViewer::ServerSide, model: true do
  include FakeBlobHelpers

  let(:project) { build(:empty_project) }

  let(:viewer_class) do
    Class.new(BlobViewer::Base) do
      include BlobViewer::ServerSide
    end
  end

  subject { viewer_class.new(blob) }

  describe '#prepare!' do
    let(:blob) { fake_blob(path: 'file.txt') }

    it 'loads all blob data' do
      expect(blob).to receive(:load_all_data!)

      subject.prepare!
    end
  end
end

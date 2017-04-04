require 'spec_helper'

describe AttachmentUploader do
  let(:uploader) { described_class.new(build_stubbed(:user)) }

  describe '#move_to_cache' do
    it 'is true' do
      expect(uploader.move_to_cache).to eq(true)
    end
  end

  describe '#move_to_store' do
    it 'is true' do
      expect(uploader.move_to_store).to eq(true)
    end
  end
end

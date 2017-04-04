require 'spec_helper'

describe AvatarUploader do
  let(:uploader) { described_class.new(build_stubbed(:user)) }

  describe '#move_to_cache' do
    it 'is false' do
      expect(uploader.move_to_cache).to eq(false)
    end
  end

  describe '#move_to_store' do
    it 'is false' do
      expect(uploader.move_to_store).to eq(false)
    end
  end
end

require 'spec_helper'

describe AvatarUploader do
  let(:uploader) { described_class.new(build_stubbed(:user)) }

  describe "#store_dir" do
    it "stores in the system dir" do
      expect(uploader.store_dir).to start_with("uploads/-/system/user")
    end

    it "uses the old path when using object storage" do
      expect(described_class).to receive(:file_storage?).and_return(false)
      expect(uploader.store_dir).to start_with("uploads/user")
    end
  end

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

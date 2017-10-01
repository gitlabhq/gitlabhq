require 'spec_helper'

describe CustomEmojiUploader do
  let(:custom_emoji) { build_stubbed(:custom_emoji) }
  let(:uploader) { described_class.new(custom_emoji) }

  describe "#store_dir" do
    it "stores in the system dir" do
      expect(uploader.store_dir).to start_with("uploads/-/system/custom_emoji/#{custom_emoji.namespace.full_path}")
    end

    it "uses the old path when using object storage" do
      expect(described_class).to receive(:file_storage?).and_return(false)
      expect(uploader.store_dir).to start_with("uploads/custom_emoji")
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

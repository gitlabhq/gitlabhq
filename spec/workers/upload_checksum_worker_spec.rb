require 'rails_helper'

describe UploadChecksumWorker do
  describe '#perform' do
    it 'rescues ActiveRecord::RecordNotFound' do
      expect { described_class.new.perform(999_999) }.not_to raise_error
    end

    it 'calls calculate_checksum_without_delay and save!' do
      upload = spy
      expect(Upload).to receive(:find).with(999_999).and_return(upload)

      described_class.new.perform(999_999)

      expect(upload).to have_received(:calculate_checksum)
      expect(upload).to have_received(:save!)
    end
  end
end

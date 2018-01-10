require 'rails_helper'

describe UploadChecksumWorker do
  describe '#perform' do
    subject { described_class.new }

    context 'without a valid record' do
      it 'rescues ActiveRecord::RecordNotFound' do
        expect { subject.perform(999_999) }.not_to raise_error
      end
    end

    context 'with a valid record' do
      let(:upload) { create(:user, :with_avatar).avatar.upload }

      before do
        expect(Upload).to receive(:find).and_return(upload)
        allow(upload).to receive(:foreground_checksumable?).and_return(false)
      end

      it 'calls calculate_checksum!' do
        expect(upload).to receive(:calculate_checksum!)
        subject.perform(upload.id)
      end

      it 'calls save!' do
        expect(upload).to receive(:save!)
        subject.perform(upload.id)
      end
    end
  end
end

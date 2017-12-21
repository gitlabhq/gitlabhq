require 'rails_helper'

describe RecordsUploads do
  let!(:uploader) do
    class RecordsUploadsExampleUploader < GitlabUploader
      include RecordsUploads

      storage :file

      def model
        FactoryBot.build_stubbed(:user)
      end
    end

    RecordsUploadsExampleUploader.new
  end

  def upload_fixture(filename)
    fixture_file_upload(Rails.root.join('spec', 'fixtures', filename))
  end

  describe 'callbacks' do
    it 'calls `record_upload` after `store`' do
      expect(uploader).to receive(:record_upload).once

      uploader.store!(upload_fixture('doc_sample.txt'))
    end

    it 'calls `destroy_upload` after `remove`' do
      expect(uploader).to receive(:destroy_upload).once

      uploader.store!(upload_fixture('doc_sample.txt'))

      uploader.remove!
    end
  end

  describe '#record_upload callback' do
    it 'returns early when not using file storage' do
      allow(uploader).to receive(:file_storage?).and_return(false)
      expect(Upload).not_to receive(:record)

      uploader.store!(upload_fixture('rails_sample.jpg'))
    end

    it "returns early when the file doesn't exist" do
      allow(uploader).to receive(:file).and_return(double(exists?: false))
      expect(Upload).not_to receive(:record)

      uploader.store!(upload_fixture('rails_sample.jpg'))
    end

    it 'creates an Upload record after store' do
      expect(Upload).to receive(:record)
        .with(uploader)

      uploader.store!(upload_fixture('rails_sample.jpg'))
    end

    it 'does not create an Upload record if model is missing' do
      expect_any_instance_of(RecordsUploadsExampleUploader).to receive(:model).and_return(nil)
      expect(Upload).not_to receive(:record).with(uploader)

      uploader.store!(upload_fixture('rails_sample.jpg'))
    end

    it 'it destroys Upload records at the same path before recording' do
      existing = Upload.create!(
        path: File.join('uploads', 'rails_sample.jpg'),
        size: 512.kilobytes,
        model: build_stubbed(:user),
        uploader: uploader.class.to_s
      )

      uploader.store!(upload_fixture('rails_sample.jpg'))

      expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(Upload.count).to eq 1
    end
  end

  describe '#destroy_upload callback' do
    it 'returns early when not using file storage' do
      uploader.store!(upload_fixture('rails_sample.jpg'))

      allow(uploader).to receive(:file_storage?).and_return(false)
      expect(Upload).not_to receive(:remove_path)

      uploader.remove!
    end

    it 'returns early when file is nil' do
      expect(Upload).not_to receive(:remove_path)

      uploader.remove!
    end

    it 'it destroys Upload records at the same path after removal' do
      uploader.store!(upload_fixture('rails_sample.jpg'))

      expect { uploader.remove! }.to change { Upload.count }.from(1).to(0)
    end
  end
end

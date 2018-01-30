require 'rails_helper'

describe RecordsUploads do
  let!(:uploader) do
    class RecordsUploadsExampleUploader < GitlabUploader
      include RecordsUploads::Concern

      storage :file

      def dynamic_segment
        'co/fe/ee'
      end
    end

    RecordsUploadsExampleUploader.new(build_stubbed(:user))
  end

  def upload_fixture(filename)
    fixture_file_upload(Rails.root.join('spec', 'fixtures', filename))
  end

  describe 'callbacks' do
    let(:upload) { create(:upload) }

    before do
      uploader.upload = upload
    end

    it '#record_upload after `store`' do
      expect(uploader).to receive(:record_upload).once

      uploader.store!(upload_fixture('doc_sample.txt'))
    end

    it '#destroy_upload after `remove`' do
      uploader.store!(upload_fixture('doc_sample.txt'))

      expect(uploader).to receive(:destroy_upload).once
      uploader.remove!
    end
  end

  describe '#record_upload callback' do
    it 'creates an Upload record after store' do
      expect { uploader.store!(upload_fixture('rails_sample.jpg')) }.to change { Upload.count }.by(1)
    end

    it 'creates a new record and assigns size, path, model, and uploader' do
      uploader.store!(upload_fixture('rails_sample.jpg'))

      upload = uploader.upload
      aggregate_failures do
        expect(upload).to be_persisted
        expect(upload.size).to eq uploader.file.size
        expect(upload.path).to eq uploader.upload_path
        expect(upload.model_id).to eq uploader.model.id
        expect(upload.model_type).to eq uploader.model.class.to_s
        expect(upload.uploader).to eq uploader.class.to_s
      end
    end

    it "does not create an Upload record when the file doesn't exist" do
      allow(uploader).to receive(:file).and_return(double(exists?: false))

      expect { uploader.store!(upload_fixture('rails_sample.jpg')) }.not_to change { Upload.count }
    end

    it 'does not create an Upload record if model is missing' do
      allow_any_instance_of(RecordsUploadsExampleUploader).to receive(:model).and_return(nil)

      expect { uploader.store!(upload_fixture('rails_sample.jpg')) }.not_to change { Upload.count }
    end

    it 'it destroys Upload records at the same path before recording' do
      existing = Upload.create!(
        path: File.join('uploads', 'rails_sample.jpg'),
        size: 512.kilobytes,
        model: build_stubbed(:user),
        uploader: uploader.class.to_s
      )

      uploader.upload = existing
      uploader.store!(upload_fixture('rails_sample.jpg'))

      expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(Upload.count).to eq(1)
    end
  end

  describe '#destroy_upload callback' do
    it 'it destroys Upload records at the same path after removal' do
      uploader.store!(upload_fixture('rails_sample.jpg'))

      expect { uploader.remove! }.to change { Upload.count }.from(1).to(0)
    end
  end
end

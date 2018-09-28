require 'spec_helper'

shared_examples_for 'model with mounted uploader' do |supports_fileuploads|
  describe '.destroy' do
    before do
      stub_uploads_object_storage(uploader_class)

      model_object.public_send(upload_attribute).migrate!(ObjectStorage::Store::REMOTE)
    end

    it 'deletes remote uploads' do
      expect_any_instance_of(CarrierWave::Storage::Fog::File).to receive(:delete).and_call_original

      expect { model_object.destroy }.to change { Upload.count }.by(-1)
    end

    it 'deletes any FileUploader uploads which are not mounted', skip: !supports_fileuploads do
      create(:upload, uploader: FileUploader, model: model_object)

      expect { model_object.destroy }.to change { Upload.count }.by(-2)
    end
  end
end

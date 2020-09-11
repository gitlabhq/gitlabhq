# frozen_string_literal: true

RSpec.shared_examples 'model with uploads' do |supports_fileuploads|
  describe '.destroy' do
    before do
      stub_uploads_object_storage(uploader_class)

      model_object.public_send(upload_attribute).migrate!(ObjectStorage::Store::REMOTE)
    end

    context 'with mounted uploader' do
      it 'deletes remote uploads' do
        expect_any_instance_of(CarrierWave::Storage::Fog::File).to receive(:delete).and_call_original

        expect { model_object.destroy! }.to change { Upload.count }.by(-1)
      end
    end

    context 'with not mounted uploads', :sidekiq_might_not_need_inline, skip: !supports_fileuploads do
      context 'with local files' do
        let!(:uploads) { create_list(:upload, 2, uploader: FileUploader, model: model_object) }

        it 'deletes any FileUploader uploads which are not mounted' do
          expect { model_object.destroy! }.to change { Upload.count }.by(-3)
        end

        it 'deletes local files' do
          expect_any_instance_of(Uploads::Local).to receive(:delete_keys).with(uploads.map(&:absolute_path))

          model_object.destroy!
        end
      end

      context 'with remote files' do
        let!(:uploads) { create_list(:upload, 2, :object_storage, uploader: FileUploader, model: model_object) }

        it 'deletes any FileUploader uploads which are not mounted' do
          expect { model_object.destroy! }.to change { Upload.count }.by(-3)
        end

        it 'deletes remote files' do
          expected_array = array_including(*uploads.map(&:path))
          expect_any_instance_of(Uploads::Fog).to receive(:delete_keys).with(expected_array)

          model_object.destroy!
        end
      end
    end
  end
end

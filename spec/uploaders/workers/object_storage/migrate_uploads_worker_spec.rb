# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::MigrateUploadsWorker do
  let(:project) { create(:project, :with_avatar) }
  let(:uploads) { Upload.all }

  def perform(uploads, store = ObjectStorage::Store::REMOTE)
    described_class.new.perform(uploads.ids, store)
  rescue ObjectStorage::MigrateUploadsWorker::Report::MigrationFailures
    # swallow
  end

  before do
    stub_uploads_object_storage(AvatarUploader)
    stub_uploads_object_storage(FileUploader)

    FileUploader.new(project).store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
  end

  describe '#perform' do
    it 'migrates files to remote storage' do
      expect(Gitlab::AppLogger).to receive(:info).with(%r{Migrated 2/2 files})

      perform(uploads)

      expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(0)
      expect(Upload.where(store: ObjectStorage::Store::REMOTE).count).to eq(2)
    end

    context 'reversed' do
      before do
        perform(uploads)
      end

      it 'migrates files to local storage' do
        expect(Upload.where(store: ObjectStorage::Store::REMOTE).count).to eq(2)

        perform(uploads, ObjectStorage::Store::LOCAL)

        expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(2)
        expect(Upload.where(store: ObjectStorage::Store::REMOTE).count).to eq(0)
      end
    end

    context 'migration is unsuccessful' do
      before do
        allow_any_instance_of(ObjectStorage::Concern)
          .to receive(:migrate!).and_raise(CarrierWave::UploadError, 'I am a teapot.')
      end

      it 'does not migrate files to remote storage' do
        expect(Gitlab::AppLogger).to receive(:warn).with(/Error .* I am a teapot/)

        perform(uploads)

        expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(2)
        expect(Upload.where(store: ObjectStorage::Store::REMOTE).count).to eq(0)
      end
    end

    describe "limits N+1 queries" do
      it "to N*5" do
        query_count = ActiveRecord::QueryRecorder.new { perform(uploads) }

        create(:project, :with_avatar)

        expect { perform(Upload.all) }.not_to exceed_query_limit(query_count).with_threshold(5)
      end
    end

    it 'handles legacy argument format' do
      described_class.new.perform(uploads.ids, 'Project', :avatar, ObjectStorage::Store::REMOTE)

      expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(0)
      expect(Upload.where(store: ObjectStorage::Store::REMOTE).count).to eq(2)
    end

    it 'logs an error when number of arguments is incorrect' do
      expect(Gitlab::AppLogger).to receive(:warn).with(/Job has wrong arguments format/)

      described_class.new.perform(uploads.ids, 'Project', ObjectStorage::Store::REMOTE)
    end
  end
end

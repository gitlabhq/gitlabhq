# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::MigrateUploadsWorker do
  let(:model_class) { Project }
  let(:uploads) { Upload.all }
  let(:to_store) { ObjectStorage::Store::REMOTE }

  def perform(uploads, store = nil)
    described_class.new.perform(uploads.ids, model_class.to_s, mounted_as, store || to_store)
  rescue ObjectStorage::MigrateUploadsWorker::Report::MigrationFailures
    # swallow
  end

  # Expects the calling spec to define:
  # - model_class
  # - mounted_as
  # - to_store
  RSpec.shared_examples 'uploads migration worker' do
    describe '.enqueue!' do
      def enqueue!
        described_class.enqueue!(uploads, model_class, mounted_as, to_store)
      end

      it 'is guarded by .sanity_check!' do
        expect(described_class).to receive(:perform_async)
        expect(described_class).to receive(:sanity_check!)

        enqueue!
      end

      context 'sanity_check! fails' do
        before do
          expect(described_class).to receive(:sanity_check!).and_raise(described_class::SanityCheckError)
        end

        it 'does not enqueue a job' do
          expect(described_class).not_to receive(:perform_async)

          expect { enqueue! }.to raise_error(described_class::SanityCheckError)
        end
      end
    end

    describe '.sanity_check!' do
      shared_examples 'raises a SanityCheckError' do |expected_message|
        let(:mount_point) { nil }

        it do
          expect { described_class.sanity_check!(uploads, model_class, mount_point) }
            .to raise_error(described_class::SanityCheckError).with_message(expected_message)
        end
      end

      context 'uploader types mismatch' do
        let!(:outlier) { create(:upload, uploader: 'GitlabUploader') }

        include_examples 'raises a SanityCheckError', /Multiple uploaders found/
      end

      context 'mount point not found' do
        include_examples 'raises a SanityCheckError', /Mount point [a-z:]+ not found in/ do
          let(:mount_point) { :potato }
        end
      end
    end

    describe '#perform' do
      it 'migrates files to remote storage' do
        expect(Gitlab::AppLogger).to receive(:info).with(%r{Migrated 1/1 files})

        perform(uploads)

        expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(0)
      end

      context 'reversed' do
        let(:to_store) { ObjectStorage::Store::LOCAL }

        before do
          perform(uploads, ObjectStorage::Store::REMOTE)
        end

        it 'migrates files to local storage' do
          expect(Upload.where(store: ObjectStorage::Store::REMOTE).count).to eq(1)

          perform(uploads)

          expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(1)
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

          expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(1)
        end
      end
    end
  end

  context "for AvatarUploader" do
    let!(:project_with_avatar) { create(:project, :with_avatar) }
    let(:mounted_as) { :avatar }

    before do
      stub_uploads_object_storage(AvatarUploader)
    end

    it_behaves_like "uploads migration worker"

    describe "limits N+1 queries" do
      it "to N*5" do
        query_count = ActiveRecord::QueryRecorder.new { perform(uploads) }

        create(:project, :with_avatar)

        expect { perform(Upload.all) }.not_to exceed_query_limit(query_count).with_threshold(5)
      end
    end
  end

  context "for FileUploader" do
    let!(:project_with_file) { create(:project) }
    let(:secret) { SecureRandom.hex }
    let(:mounted_as) { nil }

    def upload_file(project)
      uploader = FileUploader.new(project)
      uploader.store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
    end

    before do
      stub_uploads_object_storage(FileUploader)

      upload_file(project_with_file)
    end

    it_behaves_like "uploads migration worker"

    describe "limits N+1 queries" do
      it "to N*5" do
        query_count = ActiveRecord::QueryRecorder.new { perform(uploads) }

        upload_file(create(:project))

        expect { perform(Upload.all) }.not_to exceed_query_limit(query_count).with_threshold(5)
      end
    end
  end

  context 'for DesignManagement::DesignV432x230Uploader' do
    let(:model_class) { DesignManagement::Action }
    let!(:design_action) { create(:design_action, :with_image_v432x230) }
    let(:mounted_as) { :image_v432x230 }

    before do
      stub_uploads_object_storage(DesignManagement::DesignV432x230Uploader)
    end

    it_behaves_like 'uploads migration worker'
  end
end

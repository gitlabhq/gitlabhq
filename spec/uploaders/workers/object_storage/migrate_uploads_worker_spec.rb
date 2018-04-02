require 'spec_helper'

describe ObjectStorage::MigrateUploadsWorker, :sidekiq do
  shared_context 'sanity_check! fails' do
    before do
      expect(described_class).to receive(:sanity_check!).and_raise(described_class::SanityCheckError)
    end
  end

  let!(:projects) { create_list(:project, 10, :with_avatar) }
  let(:uploads) { Upload.all }
  let(:model_class) { Project }
  let(:mounted_as) { :avatar }
  let(:to_store) { ObjectStorage::Store::REMOTE }

  before do
    stub_uploads_object_storage(AvatarUploader)
  end

  describe '.enqueue!' do
    def enqueue!
      described_class.enqueue!(uploads, Project, mounted_as, to_store)
    end

    it 'is guarded by .sanity_check!' do
      expect(described_class).to receive(:perform_async)
      expect(described_class).to receive(:sanity_check!)

      enqueue!
    end

    context 'sanity_check! fails' do
      include_context 'sanity_check! fails'

      it 'does not enqueue a job' do
        expect(described_class).not_to receive(:perform_async)

        expect { enqueue! }.to raise_error(described_class::SanityCheckError)
      end
    end
  end

  describe '.sanity_check!' do
    shared_examples 'raises a SanityCheckError' do
      let(:mount_point) { nil }

      it do
        expect { described_class.sanity_check!(uploads, model_class, mount_point) }
          .to raise_error(described_class::SanityCheckError)
      end
    end

    context 'uploader types mismatch' do
      let!(:outlier) { create(:upload, uploader: 'FileUploader') }

      include_examples 'raises a SanityCheckError'
    end

    context 'model types mismatch' do
      let!(:outlier) { create(:upload, model_type: 'Potato') }

      include_examples 'raises a SanityCheckError'
    end

    context 'mount point not found' do
      include_examples 'raises a SanityCheckError' do
        let(:mount_point) { :potato }
      end
    end
  end

  describe '#perform' do
    def perform
      described_class.new.perform(uploads.ids, model_class.to_s, mounted_as, to_store)
    rescue ObjectStorage::MigrateUploadsWorker::Report::MigrationFailures
      # swallow
    end

    shared_examples 'outputs correctly' do |success: 0, failures: 0|
      total = success + failures

      if success > 0
        it 'outputs the reports' do
          expect(Rails.logger).to receive(:info).with(%r{Migrated #{success}/#{total} files})

          perform
        end
      end

      if failures > 0
        it 'outputs upload failures' do
          expect(Rails.logger).to receive(:warn).with(/Error .* I am a teapot/)

          perform
        end
      end
    end

    it_behaves_like 'outputs correctly', success: 10

    it 'migrates files' do
      perform

      aggregate_failures do
        projects.each do |project|
          expect(project.reload.avatar.upload.local?).to be_falsey
        end
      end
    end

    context 'migration is unsuccessful' do
      before do
        allow_any_instance_of(ObjectStorage::Concern).to receive(:migrate!).and_raise(CarrierWave::UploadError, "I am a teapot.")
      end

      it_behaves_like 'outputs correctly', failures: 10
    end
  end
end

# frozen_string_literal: true

# Expects the calling spec to define:
# - model_class
# - mounted_as
# - to_store
RSpec.shared_examples 'uploads migration worker' do
  def perform(uploads, store = nil)
    described_class.new.perform(uploads.ids, model_class.to_s, mounted_as, store || to_store)
  rescue ObjectStorage::MigrateUploadsWorker::Report::MigrationFailures
    # swallow
  end

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
      include_context 'sanity_check! fails'

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
    shared_examples 'outputs correctly' do |success: 0, failures: 0|
      total = success + failures

      if success > 0
        it 'outputs the reports' do
          expect(Gitlab::AppLogger).to receive(:info).with(%r{Migrated #{success}/#{total} files})

          perform(uploads)
        end
      end

      if failures > 0
        it 'outputs upload failures' do
          expect(Gitlab::AppLogger).to receive(:warn).with(/Error .* I am a teapot/)

          perform(uploads)
        end
      end
    end

    it_behaves_like 'outputs correctly', success: 10

    it 'migrates files to remote storage' do
      perform(uploads)

      expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(0)
    end

    context 'reversed' do
      let(:to_store) { ObjectStorage::Store::LOCAL }

      before do
        perform(uploads, ObjectStorage::Store::REMOTE)
      end

      it 'migrates files to local storage' do
        expect(Upload.where(store: ObjectStorage::Store::REMOTE).count).to eq(10)

        perform(uploads)

        expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(10)
      end
    end

    context 'migration is unsuccessful' do
      before do
        allow_any_instance_of(ObjectStorage::Concern)
          .to receive(:migrate!).and_raise(CarrierWave::UploadError, 'I am a teapot.')
      end

      it_behaves_like 'outputs correctly', failures: 10
    end
  end
end

RSpec.shared_context 'sanity_check! fails' do
  before do
    expect(described_class).to receive(:sanity_check!).and_raise(described_class::SanityCheckError)
  end
end

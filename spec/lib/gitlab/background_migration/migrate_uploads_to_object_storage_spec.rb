require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateUploadsToObjectStorage, :sidekiq do
  shared_context 'sanity_check! fails' do
    before do
      expect(described_class).to receive(:sanity_check!).and_raise(described_class::SanityCheckError)
    end
  end

  let(:uploads) { Upload.all }
  let(:mounted_as) { :avatar }
  let(:to_store) { ObjectStorage::Store::REMOTE }

  before do
    stub_env('BATCH', 1)
    stub_licensed_features(object_storage: true)

    create_list(:upload, 5)
  end

  describe '.enqueue!' do
    def enqueue!
      described_class.enqueue!(uploads, mounted_as, to_store)
    end

    it 'is guarded by .sanity_check!' do
      expect(described_class).to receive(:sanity_check!)

      enqueue!
    end

    context 'sanity_check! fails' do
      include_context 'sanity_check! fails'

      it 'does not enqueue a job' do
        expect(BackgroundMigrationWorker).not_to receive(:perform_async)

        expect { enqueue! }.to raise_error(described_class::SanityCheckError)
      end
    end
  end

  describe '.sanity_check!' do
    shared_examples 'raises a SanityCheckError' do
      let(:mount_point) { nil }

      it do
        expect { described_class.sanity_check!(uploads, mount_point) }.to raise_error(described_class::SanityCheckError)
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
end

require 'spec_helper'

describe ObjectStorage::MigrateUploadsWorker, :sidekiq do
  shared_context 'sanity_check! fails' do
    before do
      expect(described_class).to receive(:sanity_check!).and_raise(described_class::SanityCheckError)
    end
  end

  let(:model_class) { Project }
  let(:uploads) { Upload.all }
  let(:to_store) { ObjectStorage::Store::REMOTE }

  shared_examples "uploads migration worker" do
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

      before do
        stub_const("WrongModel", Class.new)
      end

      context 'uploader types mismatch' do
        let!(:outlier) { create(:upload, uploader: 'GitlabUploader') }

        include_examples 'raises a SanityCheckError'
      end

      context 'model types mismatch' do
        let!(:outlier) { create(:upload, model_type: 'WrongModel') }

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

        expect(Upload.where(store: ObjectStorage::Store::LOCAL).count).to eq(0)
      end

      context 'migration is unsuccessful' do
        before do
          allow_any_instance_of(ObjectStorage::Concern)
            .to receive(:migrate!).and_raise(CarrierWave::UploadError, "I am a teapot.")
        end

        it_behaves_like 'outputs correctly', failures: 10
      end
    end
  end

  context "for AvatarUploader" do
    let!(:projects) { create_list(:project, 10, :with_avatar) }
    let(:mounted_as) { :avatar }

    before do
      stub_uploads_object_storage(AvatarUploader)
    end

    it_behaves_like "uploads migration worker"
  end

  context "for FileUploader" do
    let!(:projects) { create_list(:project, 10) }
    let(:secret) { SecureRandom.hex }
    let(:mounted_as) { nil }

    before do
      stub_uploads_object_storage(FileUploader)

      projects.map do |project|
        uploader = FileUploader.new(project)
        uploader.store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
      end
    end

    it_behaves_like "uploads migration worker"
  end
end

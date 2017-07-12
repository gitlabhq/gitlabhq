require 'rails_helper'
require 'carrierwave/storage/fog'

describe ObjectStoreUploader do
  let(:uploader_class) { Class.new(described_class) }
  let(:object) { double }
  let(:uploader) { uploader_class.new(object, :artifacts_file) }

  describe '#object_store' do
    it "calls artifacts_file_store on object" do
      expect(object).to receive(:artifacts_file_store)

      uploader.object_store
    end

    context 'when store is null' do
      before do
        expect(object).to receive(:artifacts_file_store).twice.and_return(nil)
      end

      it "returns LOCAL_STORE" do
        expect(uploader.real_object_store).to be_nil
        expect(uploader.object_store).to eq(described_class::LOCAL_STORE)
      end
    end

    context 'when value is set' do
      before do
        expect(object).to receive(:artifacts_file_store).twice.and_return(described_class::REMOTE_STORE)
      end

      it "returns given value" do
        expect(uploader.real_object_store).not_to be_nil
        expect(uploader.object_store).to eq(described_class::REMOTE_STORE)
      end
    end
  end

  describe '#object_store=' do
    it "calls artifacts_file_store= on object" do
      expect(object).to receive(:artifacts_file_store=).with(described_class::REMOTE_STORE)

      uploader.object_store = described_class::REMOTE_STORE
    end
  end

  describe '#file_storage?' do
    context 'when file storage is used' do
      before do
        expect(object).to receive(:artifacts_file_store).and_return(described_class::LOCAL_STORE)
      end

      it { expect(uploader).to be_file_storage }
    end

    context 'when is remote storage' do
      before do
        uploader_class.storage_options double(
          object_store: double(enabled: true))
        expect(object).to receive(:artifacts_file_store).and_return(described_class::REMOTE_STORE)
      end

      it { expect(uploader).not_to be_file_storage }
    end
  end

  describe '#file_cache_storage?' do
    context 'when file storage is used' do
      before do
        uploader_class.cache_storage(:file)
      end

      it { expect(uploader).to be_file_cache_storage }
    end

    context 'when is remote storage' do
      before do
        uploader_class.cache_storage(:fog)
      end

      it { expect(uploader).not_to be_file_cache_storage }
    end
  end

  context 'when using ArtifactsUploader' do
    let(:job) { create(:ci_build, :artifacts, artifacts_file_store: store) }
    let(:uploader) { job.artifacts_file }

    context 'checking described_class' do
      let(:store) { described_class::LOCAL_STORE }

      it "uploader is of a described_class" do
        expect(uploader).to be_a(described_class)
      end
    end

    context 'when store is null' do
      let(:store) { nil }

      it "sets the store to LOCAL_STORE" do
        expect(job.artifacts_file_store).to eq(described_class::LOCAL_STORE)
      end
    end

    describe '#use_file' do
      context 'when file is stored locally' do
        let(:store) { described_class::LOCAL_STORE }

        it "calls a regular path" do
          expect { |b| uploader.use_file(&b) }.not_to yield_with_args(/tmp\/cache/)
        end
      end

      context 'when file is stored remotely' do
        let(:store) { described_class::REMOTE_STORE }

        before do
          stub_artifacts_object_storage
        end

        it "calls a cache path" do
          expect { |b| uploader.use_file(&b) }.to yield_with_args(/tmp\/cache/)
        end
      end
    end

    describe '#migrate!' do
      let(:job) { create(:ci_build, :artifacts, artifacts_file_store: store) }
      let(:uploader) { job.artifacts_file }
      let(:store) { described_class::LOCAL_STORE }
      
      subject { uploader.migrate!(new_store) }

      context 'when using the same storage' do
        let(:new_store) { store }

        it "to not migrate the storage" do
          subject

          expect(uploader.object_store).to eq(store)
        end
      end

      context 'when migrating to local storage' do
        let(:store) { described_class::REMOTE_STORE }
        let(:new_store) { described_class::LOCAL_STORE }
        
        before do
          stub_artifacts_object_storage
        end

        it "local file does not exist" do
          expect(File.exist?(uploader.path)).to eq(false)
        end

        it "does migrate the file" do
          subject

          expect(uploader.object_store).to eq(new_store)
          expect(File.exist?(uploader.path)).to eq(true)
        end
      end

      context 'when migrating to remote storage' do
        let(:new_store) { described_class::REMOTE_STORE }
        let!(:current_path) { uploader.path }

        it "file does exist" do
          expect(File.exist?(current_path)).to eq(true)
        end
        
        context 'when storage is disabled' do
          before do
            stub_artifacts_object_storage(enabled: false) 
          end

          it "to raise an error" do
            expect { subject }.to raise_error(/Object Storage is not enabled/)
          end
        end

        context 'when credentials are set' do
          before do
            stub_artifacts_object_storage
          end

          it "does migrate the file" do
            subject

            expect(uploader.object_store).to eq(new_store)
            expect(File.exist?(current_path)).to eq(false)
          end

          it "does delete original file" do
            subject
    
            expect(File.exist?(current_path)).to eq(false)
          end

          context 'when subject save fails' do
            before do
              expect(job).to receive(:save!).and_raise(RuntimeError, "exception")
            end

            it "does catch an error" do
              expect { subject }.to raise_error(/exception/)
            end

            it "original file is not removed" do
              begin
                subject
              rescue
              end

              expect(File.exist?(current_path)).to eq(true)
            end
          end
        end
      end
    end
  end

  describe '#fog_directory' do
    let(:remote_directory) { 'directory' }

    before do
      uploader_class.storage_options double(
        object_store: double(remote_directory: remote_directory))
    end

    subject { uploader.fog_directory }

    it { is_expected.to eq(remote_directory) }
  end

  describe '#fog_credentials' do
    let(:connection) { 'connection' }

    before do
      uploader_class.storage_options double(
        object_store: double(connection: connection))
    end

    subject { uploader.fog_credentials }

    it { is_expected.to eq(connection) }
  end

  describe '#fog_public' do
    subject { uploader.fog_public }

    it { is_expected.to eq(false) }
  end

  describe '#verify_license!' do
    subject { uploader.verify_license!(nil) }

    context 'when using local storage' do
      before do
        expect(object).to receive(:artifacts_file_store) { described_class::LOCAL_STORE }
      end

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context 'when using remote storage' do
      let(:project) { double }

      before do
        uploader_class.storage_options double(
          object_store: double(enabled: true))
        expect(object).to receive(:artifacts_file_store) { described_class::REMOTE_STORE }
        expect(object).to receive(:project) { project }
      end

      context 'feature is not available' do
        before do
          expect(project).to receive(:feature_available?).with(:object_storage) { false }
        end

        it "does raise an error" do
          expect { subject }.to raise_error(/Object Storage feature is missing/)
        end
      end

      context 'feature is available' do
        before do
          expect(project).to receive(:feature_available?).with(:object_storage) { true }
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end
    end
  end
end

require 'rails_helper'
require 'carrierwave/storage/fog'

class Implementation < GitlabUploader
  include ObjectStorage::Concern
  include ::RecordsUploads::Concern
  prepend ::ObjectStorage::Extension::RecordsUploads

  storage_options Gitlab.config.uploads

  private

  # user/:id
  def dynamic_segment
    File.join(model.class.to_s.underscore, model.id.to_s)
  end
end

describe ObjectStorage do
  let(:uploader_class) { Implementation }
  let(:object) { build_stubbed(:user) }
  let(:uploader) { uploader_class.new(object, :file) }

  before do
    allow(uploader_class).to receive(:object_store_enabled?).and_return(true)
  end

  describe '#object_store=' do
    it "reload the local storage" do
      uploader.object_store = described_class::Store::LOCAL
      expect(uploader.file_storage?).to be_truthy
    end

    it "reload the REMOTE storage" do
      uploader.object_store = described_class::Store::REMOTE
      expect(uploader.file_storage?).to be_falsey
    end
  end

  context 'object_store is Store::LOCAL' do
    before do
      uploader.object_store = described_class::Store::LOCAL
    end

    describe '#store_dir' do
      it 'is the composition of (base_dir, dynamic_segment)' do
        expect(uploader.store_dir).to start_with("uploads/-/system/user/")
      end
    end
  end

  context 'object_store is Store::REMOTE' do
    before do
      uploader.object_store = described_class::Store::REMOTE
    end

    describe '#store_dir' do
      it 'is the composition of (dynamic_segment)' do
        expect(uploader.store_dir).to start_with("user/")
      end
    end
  end

  describe '#object_store' do
    it "delegates to <mount>_store on model" do
      expect(object).to receive(:file_store)

      uploader.object_store
    end

    context 'when store is null' do
      before do
        expect(object).to receive(:file_store).and_return(nil)
      end

      it "returns Store::LOCAL" do
        expect(uploader.object_store).to eq(described_class::Store::LOCAL)
      end
    end

    context 'when value is set' do
      before do
        expect(object).to receive(:file_store).and_return(described_class::Store::REMOTE)
      end

      it "returns the given value" do
        expect(uploader.object_store).to eq(described_class::Store::REMOTE)
      end
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

  # this means the model shall include
  #   include RecordsUpload::Concern
  #   prepend ObjectStorage::Extension::RecordsUploads
  # the object_store persistence is delegated to the `Upload` model.
  #
  context 'when persist_object_store? is false' do
    let(:object) { create(:project, :with_avatar) }
    let(:uploader) { object.avatar }

    it { expect(object).to be_a(Avatarable) }
    it { expect(uploader.persist_object_store?).to be_falsey }

    describe 'delegates the object_store logic to the `Upload` model' do
      it 'sets @upload to the found `upload`' do
        expect(uploader.upload).to eq(uploader.upload)
      end

      it 'sets @object_store to the `Upload` value' do
        expect(uploader.object_store).to eq(uploader.upload.store)
      end
    end

    describe '#migrate!' do
      let(:new_store) { ObjectStorage::Store::REMOTE }

      before do
        stub_uploads_object_storage(uploader: AvatarUploader)
      end

      subject { uploader.migrate!(new_store) }

      it 'persist @object_store to the recorded upload' do
        subject

        expect(uploader.upload.store).to eq(new_store)
      end

      describe 'fails' do
        it 'is handled gracefully' do
          store = uploader.object_store
          expect_any_instance_of(Upload).to receive(:save!).and_raise("An error")

          expect { subject }.to raise_error("An error")
          expect(uploader.exists?).to be_truthy
          expect(uploader.upload.store).to eq(store)
        end
      end
    end
  end

  # this means the model holds an <mounted_as>_store attribute directly
  # and do not delegate the object_store persistence to the `Upload` model.
  #
  context 'persist_object_store? is true' do
    context 'when using JobArtifactsUploader' do
      let(:store) { described_class::Store::LOCAL }
      let(:object) { create(:ci_job_artifact, :archive, file_store: store) }
      let(:uploader) { object.file }

      context 'checking described_class' do
        it "uploader include described_class::Concern" do
          expect(uploader).to be_a(described_class::Concern)
        end
      end

      describe '#use_file' do
        context 'when file is stored locally' do
          it "calls a regular path" do
            expect { |b| uploader.use_file(&b) }.not_to yield_with_args(%r[tmp/cache])
          end
        end

        context 'when file is stored remotely' do
          let(:store) { described_class::Store::REMOTE }

          before do
            stub_artifacts_object_storage
          end

          it "calls a cache path" do
            expect { |b| uploader.use_file(&b) }.to yield_with_args(%r[tmp/cache])
          end
        end
      end

      describe '#migrate!' do
        subject { uploader.migrate!(new_store) }

        shared_examples "updates the underlying <mounted>_store" do
          it do
            subject

            expect(object.file_store).to eq(new_store)
          end
        end

        context 'when using the same storage' do
          let(:new_store) { store }

          it "to not migrate the storage" do
            subject

            expect(uploader).not_to receive(:store!)
            expect(uploader.object_store).to eq(store)
          end
        end

        context 'when migrating to local storage' do
          let(:store) { described_class::Store::REMOTE }
          let(:new_store) { described_class::Store::LOCAL }

          before do
            stub_artifacts_object_storage
          end

          include_examples "updates the underlying <mounted>_store"

          it "local file does not exist" do
            expect(File.exist?(uploader.path)).to eq(false)
          end

          it "remote file exist" do
            expect(uploader.file.exists?).to be_truthy
          end

          it "does migrate the file" do
            subject

            expect(uploader.object_store).to eq(new_store)
            expect(File.exist?(uploader.path)).to eq(true)
          end
        end

        context 'when migrating to remote storage' do
          let(:new_store) { described_class::Store::REMOTE }
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

            include_examples "updates the underlying <mounted>_store"

            it "does migrate the file" do
              subject

              expect(uploader.object_store).to eq(new_store)
            end

            it "does delete original file" do
              subject

              expect(File.exist?(current_path)).to eq(false)
            end

            context 'when subject save fails' do
              before do
                expect(uploader).to receive(:persist_object_store!).and_raise(RuntimeError, "exception")
              end

              it "original file is not removed" do
                expect { subject }.to raise_error(/exception/)

                expect(File.exist?(current_path)).to eq(true)
              end
            end
          end
        end
      end
    end
  end

  describe '#fog_directory' do
    let(:remote_directory) { 'directory' }

    before do
      uploader_class.storage_options double(object_store: double(remote_directory: remote_directory))
    end

    subject { uploader.fog_directory }

    it { is_expected.to eq(remote_directory) }
  end

  describe '#fog_credentials' do
    let(:connection) { Settingslogic.new("provider" => "AWS") }

    before do
      uploader_class.storage_options double(object_store: double(connection: connection))
    end

    subject { uploader.fog_credentials }

    it { is_expected.to eq(provider: 'AWS') }
  end

  describe '#fog_public' do
    subject { uploader.fog_public }

    it { is_expected.to eq(false) }
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'carrierwave/storage/fog'

class Implementation < GitlabUploader
  include ObjectStorage::Concern
  include ::RecordsUploads::Concern
  prepend ::ObjectStorage::Extension::RecordsUploads

  storage_location :uploads

  private

  # user/:id
  def dynamic_segment
    File.join(model.class.underscore, model.id.to_s)
  end
end

# TODO: Update feature_category once object storage group ownership has been determined.
RSpec.describe ObjectStorage, :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:uploader_class) { Implementation }
  let(:object) { build_stubbed(:user) }
  let(:file_column) { :file }
  let(:uploader) { uploader_class.new(object, file_column) }

  describe '#object_store=' do
    before do
      allow(uploader_class).to receive(:object_store_enabled?).and_return(true)
    end

    it "reload the local storage" do
      uploader.object_store = described_class::Store::LOCAL
      expect(uploader.file_storage?).to be_truthy
    end

    it "reload the REMOTE storage" do
      uploader.object_store = described_class::Store::REMOTE
      expect(uploader.file_storage?).to be_falsey
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

      describe '#store_path' do
        subject { uploader.store_path('filename') }

        it 'uses store_dir' do
          expect(subject).to eq("uploads/-/system/user/#{object.id}/filename")
        end

        context 'when a bucket prefix is configured' do
          before do
            allow(uploader_class).to receive(:object_store_options) do
              double(
                bucket_prefix: 'my/prefix'
              )
            end
          end

          it 'uses store_dir and ignores prefix' do
            expect(subject).to eq("uploads/-/system/user/#{object.id}/filename")
          end
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

      describe '#store_path' do
        subject { uploader.store_path('filename') }

        it 'uses store_dir' do
          expect(subject).to eq("user/#{object.id}/filename")
        end

        context 'when a bucket prefix is configured' do
          before do
            allow(uploader_class).to receive(:object_store_options) do
              double(
                bucket_prefix: 'my/prefix'
              )
            end
          end

          it 'uses the prefix and store_dir' do
            expect(subject).to eq("my/prefix/user/#{object.id}/filename")
          end
        end

        context 'when model has final path defined for the file column' do
          # Changing this to `foo` to make a point that not all uploaders are mounted
          # as `file`. They can be mounted as different names, for example, `avatar`.
          let(:file_column) { :foo }

          before do
            allow(object).to receive(:foo_final_path).and_return('123-final-path')
          end

          it 'uses the final path instead' do
            expect(subject).to eq('123-final-path')
          end

          context 'and a bucket prefix is configured' do
            before do
              allow(uploader_class).to receive(:object_store_options) do
                double(
                  bucket_prefix: 'my/prefix'
                )
              end
            end

            it 'uses the prefix with the final path' do
              expect(subject).to eq("my/prefix/123-final-path")
            end
          end
        end
      end
    end

    context 'with a model that persist object store' do
      before do
        allow(uploader).to receive_messages(sync_model_object_store?: false, persist_object_store?: true)
      end

      it 'does not sync with the model' do
        expect(object).not_to receive(:"[]=")

        uploader.object_store = described_class::Store::LOCAL
      end

      context 'with an uploader that sync with the model' do
        before do
          allow(uploader).to receive(:sync_model_object_store?).and_return(true)
        end

        it 'syncs with the model' do
          expect(object).to receive(:"[]=").with(:file_store, described_class::Store::LOCAL)

          uploader.object_store = described_class::Store::LOCAL
        end
      end
    end
  end

  describe '#object_store' do
    subject { uploader.object_store }

    it "delegates to <mount>_store on model" do
      expect(object).to receive(:file_store)

      subject
    end

    context 'when store is null' do
      before do
        expect(object).to receive(:file_store).and_return(nil)
      end

      it "uses Store::LOCAL" do
        is_expected.to eq(described_class::Store::LOCAL)
      end
    end

    context 'when value is set' do
      before do
        expect(object).to receive(:file_store).and_return(described_class::Store::REMOTE)
      end

      it "returns the given value" do
        is_expected.to eq(described_class::Store::REMOTE)
      end
    end
  end

  describe '#file_cache_storage?' do
    context 'when file storage is used' do
      before do
        expect(uploader_class).to receive(:cache_storage) { CarrierWave::Storage::File }
      end

      it { expect(uploader).to be_file_cache_storage }
    end

    context 'when is remote storage' do
      before do
        expect(uploader_class).to receive(:cache_storage) { CarrierWave::Storage::Fog }
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
          expect_next_instance_of(Upload) do |instance|
            expect(instance).to receive(:save!).and_raise("An error")
          end

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
            expect { |b| uploader.use_file(&b) }.not_to yield_with_args(%r{tmp/cache})
          end
        end

        context 'when file is stored remotely' do
          let(:store) { described_class::Store::REMOTE }

          before do
            stub_artifacts_object_storage
          end

          it "calls a cache path" do
            expect { |b| uploader.use_file(&b) }.to yield_with_args(%r{tmp/cache})
          end

          it "cleans up the cached file" do
            cached_path = ''

            uploader.use_file do |path|
              cached_path = path

              expect(File.exist?(cached_path)).to be_truthy
            end

            expect(File.exist?(cached_path)).to be_falsey
          end
        end
      end

      describe '#use_open_file' do
        context 'when file is stored locally' do
          it "returns the file unlinked" do
            expect { |b| uploader.use_open_file(&b) }.to yield_with_args(
              satisfying do |f|
                expect(f).to be_an_instance_of(ObjectStorage::Concern::OpenFile)
                expect(f.file_path).to be_nil
                expect(f.original_filename).to be_nil
              end
            )
          end

          it "returns the file not unlinked" do
            expect { |b| uploader.use_open_file(unlink_early: false, &b) }.to yield_with_args(
              satisfying do |f|
                expect(f).to be_an_instance_of(ObjectStorage::Concern::OpenFile)
                expect(File.exist?(f.file_path)).to be_truthy
                expect(f.original_filename).not_to be_nil
                expect(f.original_filename).to eq(File.basename(f.file_path))
              end
            )
          end
        end

        context 'when file is stored remotely' do
          let(:store) { described_class::Store::REMOTE }

          before do
            stub_artifacts_object_storage

            # We need to check the Host header not including the port because AWS does not accept
            stub_request(:get, %r{s3.amazonaws.com/#{uploader.path}})
              .with { |request| request.headers['Host'].to_s.exclude?(':443') }
              .to_return(status: 200, body: '')
          end

          it "returns the file" do
            expect { |b| uploader.use_open_file(&b) }.to yield_with_args(an_instance_of(ObjectStorage::Concern::OpenFile))
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
              expect { subject }.to raise_error(/Object Storage is not enabled for JobArtifactUploader/)
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
      allow(uploader_class).to receive(:options) do
        double(object_store: double(remote_directory: remote_directory))
      end
    end

    subject { uploader.fog_directory }

    it { is_expected.to eq(remote_directory) }
  end

  context 'when file is in use' do
    def when_file_is_in_use
      uploader.use_file do
        yield
      end
    end

    it 'cannot migrate' do
      when_file_is_in_use do
        expect(uploader).not_to receive(:unsafe_migrate!)

        expect { uploader.migrate!(described_class::Store::REMOTE) }.to raise_error(ObjectStorage::ExclusiveLeaseTaken)
      end
    end

    it 'cannot use_file' do
      when_file_is_in_use do
        expect(uploader).not_to receive(:unsafe_use_file)

        expect { uploader.use_file }.to raise_error(ObjectStorage::ExclusiveLeaseTaken)
      end
    end

    it 'can still migrate other files of the same model' do
      uploader2 = uploader_class.new(object, :file)
      uploader2.upload = create(:upload)
      uploader.upload = create(:upload)

      when_file_is_in_use do
        expect(uploader2).to receive(:unsafe_migrate!)

        uploader2.migrate!(described_class::Store::REMOTE)
      end
    end
  end

  describe '#fog_credentials' do
    let(:connection) { GitlabSettings::Options.build("provider" => "AWS") }

    before do
      allow(uploader_class).to receive(:options) do
        double(object_store: double(connection: connection))
      end
    end

    subject { uploader.fog_credentials }

    it { is_expected.to eq(provider: 'AWS') }
  end

  describe '#fog_public' do
    subject { uploader.fog_public }

    it { is_expected.to eq(nil) }
  end

  describe '#fog_attributes' do
    subject { uploader.fog_attributes }

    it { is_expected.to eq({}) }

    context 'with encryption configured' do
      let(:raw_options) do
        {
          "enabled" => true,
          "connection" => { "provider" => 'AWS' },
          "storage_options" => { "server_side_encryption" => "AES256" }
        }
      end

      let(:options) { GitlabSettings::Options.build(raw_options) }

      before do
        allow(uploader_class).to receive(:options) do
          double(object_store: options)
        end
      end

      it { is_expected.to eq({ "x-amz-server-side-encryption" => "AES256" }) }
    end
  end

  describe '.workhorse_authorize' do
    let(:has_length) { true }
    let(:maximum_size) { nil }
    let(:use_final_store_path) { false }
    let(:final_store_path_root_hash) { nil }
    let(:final_store_path_config) { { root_hash: final_store_path_root_hash } }

    subject do
      uploader_class.workhorse_authorize(
        has_length: has_length,
        maximum_size: maximum_size,
        use_final_store_path: use_final_store_path,
        final_store_path_config: final_store_path_config
      )
    end

    context 'when FIPS is enabled', :fips_mode do
      it 'response enables FIPS' do
        expect(subject[:UploadHashFunctions]).to match_array(%w[sha1 sha256 sha512])
      end
    end

    context 'when FIPS is disabled' do
      it 'response disables FIPS' do
        expect(subject[:UploadHashFunctions]).to be nil
      end
    end

    shared_examples 'returns the maximum size given' do
      it "returns temporary path" do
        expect(subject[:MaximumSize]).to eq(maximum_size)
      end
    end

    shared_examples 'uses local storage' do
      it_behaves_like 'returns the maximum size given' do
        it "returns temporary path" do
          is_expected.to have_key(:TempPath)

          expect(subject[:TempPath]).to start_with(uploader_class.root)
          expect(subject[:TempPath]).to include(described_class::TMP_UPLOAD_PATH)
        end
      end
    end

    shared_examples 'uses remote storage' do
      it_behaves_like 'returns the maximum size given' do
        it "returns remote object properties for a temporary upload" do
          is_expected.to have_key(:RemoteObject)

          expect(subject[:RemoteObject]).to have_key(:ID)
          expect(subject[:RemoteObject]).to include(Timeout: a_kind_of(Integer))
          expect(subject[:RemoteObject][:Timeout]).to be(ObjectStorage::DirectUpload::TIMEOUT)

          upload_path = File.join(described_class::TMP_UPLOAD_PATH, subject[:RemoteObject][:ID])

          expect(subject[:RemoteObject][:GetURL]).to include(upload_path)
          expect(subject[:RemoteObject][:DeleteURL]).to include(upload_path)
          expect(subject[:RemoteObject][:StoreURL]).to include(upload_path)
          expect(subject[:RemoteObject][:SkipDelete]).to eq(false)

          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hlen(ObjectStorage::PendingDirectUpload::KEY)).to be_zero
          end
        end
      end
    end

    shared_examples 'uses remote storage with multipart uploads' do
      it_behaves_like 'uses remote storage' do
        it "returns multipart upload" do
          is_expected.to have_key(:RemoteObject)

          expect(subject[:RemoteObject]).to have_key(:MultipartUpload)
          expect(subject[:RemoteObject][:MultipartUpload]).to have_key(:PartSize)

          upload_path = File.join(described_class::TMP_UPLOAD_PATH, subject[:RemoteObject][:ID])

          expect(subject[:RemoteObject][:MultipartUpload][:PartURLs]).to all(include(upload_path))
          expect(subject[:RemoteObject][:MultipartUpload][:CompleteURL]).to include(upload_path)
          expect(subject[:RemoteObject][:MultipartUpload][:AbortURL]).to include(upload_path)
        end
      end
    end

    shared_examples 'uses remote storage without multipart uploads' do
      it_behaves_like 'uses remote storage' do
        it "does not return multipart upload" do
          is_expected.to have_key(:RemoteObject)
          expect(subject[:RemoteObject]).not_to have_key(:MultipartUpload)
        end
      end
    end

    shared_examples 'handling object storage final upload path' do |multipart|
      context 'when use_final_store_path is true' do
        let(:use_final_store_path) { true }
        let(:final_store_path_root_hash) { 12345 }
        let(:final_store_path) { File.join('@final', 'myprefix', 'abc', '123', 'somefilename') }
        let(:escaped_path) { escape_path(final_store_path) }

        context 'and final_store_path_root_hash was not given' do
          let(:final_store_path_root_hash) { nil }

          it 'raises an error' do
            expect { subject }.to raise_error(ObjectStorage::MissingFinalStorePathRootId)
          end
        end

        context 'and final_store_path_root_hash was given' do
          before do
            stub_object_storage_multipart_init_with_final_store_path("#{storage_url}#{final_store_path}") if multipart

            allow(uploader_class).to receive(:generate_final_store_path)
              .with(root_hash: final_store_path_root_hash)
              .and_return(final_store_path)
          end

          it 'uses the full path instead of the temporary one' do
            expect(subject[:RemoteObject][:ID]).to eq(final_store_path)

            expect(subject[:RemoteObject][:GetURL]).to include(escaped_path)
            expect(subject[:RemoteObject][:StoreURL]).to include(escaped_path)

            if multipart
              expect(subject[:RemoteObject][:MultipartUpload][:PartURLs]).to all(include(escaped_path))
              expect(subject[:RemoteObject][:MultipartUpload][:CompleteURL]).to include(escaped_path)
              expect(subject[:RemoteObject][:MultipartUpload][:AbortURL]).to include(escaped_path)
            end

            expect(subject[:RemoteObject][:SkipDelete]).to eq(true)

            expect(
              ObjectStorage::PendingDirectUpload.exists?(uploader_class.storage_location_identifier, final_store_path)
            ).to eq(true)
          end

          context 'and bucket prefix is configured' do
            let(:prefixed_final_store_path) { "my/prefix/#{final_store_path}" }
            let(:escaped_path) { escape_path(prefixed_final_store_path) }

            before do
              allow(uploader_class.object_store_options).to receive(:bucket_prefix).and_return('my/prefix')

              if multipart
                stub_object_storage_multipart_init_with_final_store_path("#{storage_url}#{prefixed_final_store_path}")
              end
            end

            it 'sets the remote object ID to the final path without prefix' do
              expect(subject[:RemoteObject][:ID]).to eq(final_store_path)
            end

            it 'returns the final path with prefix' do
              expect(subject[:RemoteObject][:GetURL]).to include(escaped_path)
              expect(subject[:RemoteObject][:StoreURL]).to include(escaped_path)

              if multipart
                expect(subject[:RemoteObject][:MultipartUpload][:PartURLs]).to all(include(escaped_path))
                expect(subject[:RemoteObject][:MultipartUpload][:CompleteURL]).to include(escaped_path)
                expect(subject[:RemoteObject][:MultipartUpload][:AbortURL]).to include(escaped_path)
              end
            end

            it 'creates the pending upload entry without the bucket prefix' do
              is_expected.to have_key(:RemoteObject)

              expect(
                ObjectStorage::PendingDirectUpload.exists?(uploader_class.storage_location_identifier, final_store_path)
              ).to eq(true)
            end
          end
        end

        context 'and override_path was given' do
          let(:override_path) { 'test_override_path' }
          let(:final_store_path_config) { { override_path: override_path } }

          before do
            stub_object_storage_multipart_init_with_final_store_path("#{storage_url}#{override_path}") if multipart
          end

          it 'uses the override instead of generating a path' do
            expect(uploader_class).not_to receive(:generate_final_store_path)

            expect(subject[:RemoteObject][:ID]).to eq(override_path)
            expect(subject[:RemoteObject][:GetURL]).to include(override_path)
            expect(subject[:RemoteObject][:StoreURL]).to include(override_path)

            if multipart
              expect(subject[:RemoteObject][:MultipartUpload][:PartURLs]).to all(include(override_path))
              expect(subject[:RemoteObject][:MultipartUpload][:CompleteURL]).to include(override_path)
              expect(subject[:RemoteObject][:MultipartUpload][:AbortURL]).to include(override_path)
            end

            expect(subject[:RemoteObject][:SkipDelete]).to eq(true)

            expect(
              ObjectStorage::PendingDirectUpload.exists?(uploader_class.storage_location_identifier, override_path)
            ).to eq(true)
          end
        end
      end

      def escape_path(path)
        # This is what the private method Fog::AWS::Storage#object_to_path will do to the object name
        Fog::AWS.escape(path).gsub('%2F', '/')
      end
    end

    context 'when object storage is disabled' do
      before do
        allow(Gitlab.config.uploads.object_store).to receive(:enabled) { false }
      end

      it_behaves_like 'uses local storage'
    end

    context 'when object storage is enabled' do
      before do
        allow(Gitlab.config.uploads.object_store).to receive(:enabled) { true }
      end

      context 'when direct upload is enabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:direct_upload) { true }
        end

        context 'uses AWS' do
          let(:storage_url) { "https://uploads.s3.eu-central-1.amazonaws.com/" }
          let(:credentials) do
            {
              provider: "AWS",
              aws_access_key_id: "AWS_ACCESS_KEY_ID",
              aws_secret_access_key: "AWS_SECRET_ACCESS_KEY",
              region: "eu-central-1"
            }
          end

          before do
            allow_next_instance_of(ObjectStorage::Config) do |instance|
              allow(instance).to receive(:credentials).and_return(credentials)
            end
          end

          context 'for known length' do
            it_behaves_like 'uses remote storage without multipart uploads' do
              it 'returns links for S3' do
                expect(subject[:RemoteObject][:GetURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:DeleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:StoreURL]).to start_with(storage_url)
              end
            end

            it_behaves_like 'handling object storage final upload path'
          end

          context 'for unknown length' do
            let(:has_length) { false }
            let(:maximum_size) { 1.gigabyte }

            before do
              stub_object_storage_multipart_init(storage_url)
            end

            it_behaves_like 'uses remote storage with multipart uploads' do
              it 'returns links for S3' do
                expect(subject[:RemoteObject][:GetURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:DeleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:StoreURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:MultipartUpload][:PartURLs]).to all(start_with(storage_url))
                expect(subject[:RemoteObject][:MultipartUpload][:CompleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:MultipartUpload][:AbortURL]).to start_with(storage_url)
              end
            end

            it_behaves_like 'handling object storage final upload path', :multipart
          end
        end

        context 'uses Google' do
          let(:storage_url) { "https://storage.googleapis.com/uploads/" }
          let(:credentials) do
            {
              provider: "Google",
              google_storage_access_key_id: 'ACCESS_KEY_ID',
              google_storage_secret_access_key: 'SECRET_ACCESS_KEY'
            }
          end

          before do
            allow_next_instance_of(ObjectStorage::Config) do |instance|
              allow(instance).to receive(:credentials).and_return(credentials)
            end
          end

          context 'for known length' do
            it_behaves_like 'uses remote storage without multipart uploads' do
              it 'returns links for Google Cloud' do
                expect(subject[:RemoteObject][:GetURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:DeleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:StoreURL]).to start_with(storage_url)
              end
            end

            it_behaves_like 'handling object storage final upload path'
          end

          context 'for unknown length' do
            let(:has_length) { false }
            let(:maximum_size) { 1.gigabyte }

            it_behaves_like 'uses remote storage without multipart uploads' do
              it 'returns links for Google Cloud' do
                expect(subject[:RemoteObject][:GetURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:DeleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:StoreURL]).to start_with(storage_url)
              end
            end

            it_behaves_like 'handling object storage final upload path'
          end
        end

        context 'uses GDK/minio' do
          let(:storage_url) { "http://minio:9000/uploads/" }
          let(:credentials) do
            { provider: "AWS",
              aws_access_key_id: "AWS_ACCESS_KEY_ID",
              aws_secret_access_key: "AWS_SECRET_ACCESS_KEY",
              endpoint: 'http://minio:9000',
              path_style: true,
              region: "gdk" }
          end

          before do
            allow_next_instance_of(ObjectStorage::Config) do |instance|
              allow(instance).to receive(:credentials).and_return(credentials)
            end
          end

          context 'for known length' do
            it_behaves_like 'uses remote storage without multipart uploads' do
              it 'returns links for S3' do
                expect(subject[:RemoteObject][:GetURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:DeleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:StoreURL]).to start_with(storage_url)
              end
            end

            it_behaves_like 'handling object storage final upload path'
          end

          context 'for unknown length' do
            let(:has_length) { false }
            let(:maximum_size) { 1.gigabyte }

            before do
              stub_object_storage_multipart_init(storage_url)
            end

            it_behaves_like 'uses remote storage with multipart uploads' do
              it 'returns links for S3' do
                expect(subject[:RemoteObject][:GetURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:DeleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:StoreURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:MultipartUpload][:PartURLs]).to all(start_with(storage_url))
                expect(subject[:RemoteObject][:MultipartUpload][:CompleteURL]).to start_with(storage_url)
                expect(subject[:RemoteObject][:MultipartUpload][:AbortURL]).to start_with(storage_url)
              end
            end

            it_behaves_like 'handling object storage final upload path', :multipart
          end
        end
      end

      context 'when direct upload is disabled' do
        before do
          allow(Gitlab.config.uploads.object_store).to receive(:direct_upload) { false }
        end

        it_behaves_like 'uses local storage'
      end
    end
  end

  describe '#cache!' do
    subject do
      uploader.cache!(uploaded_file)
    end

    context 'when local file is used' do
      let(:temp_file) { Tempfile.new("test") }

      before do
        FileUtils.touch(temp_file)
      end

      after do
        FileUtils.rm_f(temp_file)
      end

      context 'when valid file is used' do
        context 'when valid file is specified' do
          let(:uploaded_file) { temp_file }

          it 'properly caches the file' do
            subject

            expect(uploader).to be_exists
            expect(uploader.path).to start_with(uploader_class.root)
            expect(uploader.filename).to eq(File.basename(uploaded_file.path))
          end

          context 'when object storage and direct upload is specified' do
            before do
              stub_uploads_object_storage(uploader_class, enabled: true, direct_upload: true)
            end

            context 'when file is stored' do
              subject do
                uploader.store!(uploaded_file)
              end

              it 'file to be remotely stored in permament location' do
                subject

                expect(uploader).to be_exists
                expect(uploader).not_to be_cached
                expect(uploader).not_to be_file_storage
                expect(uploader.path).not_to be_nil
                expect(uploader.path).not_to include('tmp/upload')
                expect(uploader.path).not_to include('tmp/cache')
                expect(uploader.object_store).to eq(described_class::Store::REMOTE)
              end
            end
          end

          context 'when object storage and direct upload is not used' do
            before do
              stub_uploads_object_storage(uploader_class, enabled: true, direct_upload: false)
            end

            context 'when file is stored' do
              subject do
                uploader.store!(uploaded_file)
              end

              it 'file to be remotely stored in permament location' do
                subject

                expect(uploader).to be_exists
                expect(uploader).not_to be_cached
                expect(uploader).to be_file_storage
                expect(uploader.path).not_to be_nil
                expect(uploader.path).not_to include('tmp/upload')
                expect(uploader.path).not_to include('tmp/cache')
                expect(uploader.object_store).to eq(described_class::Store::LOCAL)
              end
            end
          end
        end
      end
    end

    context 'when remote file is used' do
      let(:temp_file) { Tempfile.new("test") }

      let!(:fog_connection) do
        stub_uploads_object_storage(uploader_class)
      end

      before do
        FileUtils.touch(temp_file)
      end

      after do
        FileUtils.rm_f(temp_file)
      end

      context 'when valid file is used' do
        context 'when invalid file is specified' do
          let(:uploaded_file) do
            UploadedFile.new(temp_file.path, remote_id: "../test/123123")
          end

          it 'raises an error' do
            expect { subject }.to raise_error(uploader_class::RemoteStoreError, /Bad file path/)
          end
        end

        context 'when non existing file is specified' do
          let(:uploaded_file) do
            UploadedFile.new(temp_file.path, remote_id: "test/123123")
          end

          it 'raises an error' do
            expect { subject }.to raise_error(uploader_class::RemoteStoreError, /Missing file/)
          end

          context 'when check_remote_file_existence_on_upload? is set to false' do
            before do
              allow(uploader).to receive(:check_remote_file_existence_on_upload?).and_return(false)
            end

            it 'does not raise an error' do
              expect { subject }.not_to raise_error
            end
          end
        end

        context 'when empty remote_id is specified' do
          let(:uploaded_file) do
            UploadedFile.new(temp_file.path, remote_id: '')
          end

          it 'uses local storage' do
            subject

            expect(uploader).to be_file_storage
            expect(uploader.object_store).to eq(described_class::Store::LOCAL)
          end
        end

        context 'when valid file is specified' do
          let(:uploaded_file) do
            UploadedFile.new(temp_file.path, filename: "my_file.txt", remote_id: "test/123123")
          end

          let!(:fog_file) do
            fog_connection.directories.new(key: 'uploads').files.create( # rubocop:disable Rails/SaveBang
              key: 'tmp/uploads/test/123123',
              body: 'content'
            )
          end

          it 'file to be cached and remote stored' do
            expect { subject }.not_to raise_error

            expect(uploader).to be_exists
            expect(uploader).to be_cached
            expect(uploader.cache_only).to be_falsey
            expect(uploader).not_to be_file_storage
            expect(uploader.path).not_to be_nil
            expect(uploader.path).to include('tmp/uploads')
            expect(uploader.path).not_to include('tmp/cache')
            expect(uploader.object_store).to eq(described_class::Store::REMOTE)
          end

          context 'when file is stored' do
            subject do
              uploader.store!(uploaded_file)
            end

            it 'file to be remotely stored in permament location' do
              subject

              expect(uploader).to be_exists
              expect(uploader).not_to be_cached
              expect(uploader).not_to be_file_storage
              expect(uploader.path).not_to be_nil
              expect(uploader.path).not_to include('tmp/upload')
              expect(uploader.path).not_to include('tmp/cache')
              expect(uploader.url).to include('/my_file.txt')
              expect(uploader.object_store).to eq(described_class::Store::REMOTE)
            end
          end

          context 'when uploaded file remote_id matches a pending direct upload entry' do
            let(:uploader_class) do
              Class.new(GitlabUploader) do
                include ObjectStorage::Concern
              end
            end

            let(:object) { build_stubbed(:ci_job_artifact) }
            let(:final_path) { '@final/test/123123' }
            let(:fog_config) { Gitlab.config.uploads.object_store }
            let(:bucket) { 'uploads' }
            let(:uploaded_file) { UploadedFile.new(temp_file.path, filename: "my_file.txt", remote_id: final_path) }
            let(:fog_file_path) { final_path }

            let(:fog_connection_2) do
              stub_object_storage_uploader(
                config: fog_config,
                uploader: uploader_class,
                direct_upload: true
              )
            end

            let!(:fog_file_2) do
              fog_connection_2.directories.new(key: bucket).files.create( # rubocop:disable Rails/SaveBang
                key: fog_file_path,
                body: 'content'
              )
            end

            before do
              ObjectStorage::PendingDirectUpload.prepare(
                uploader_class.storage_location_identifier,
                final_path
              )
            end

            it 'file to be cached and remote stored with final path set' do
              expect { subject }.not_to raise_error

              expect(uploader).to be_exists
              expect(uploader).to be_cached
              expect(uploader.cache_only).to be_falsey
              expect(uploader).not_to be_file_storage
              expect(uploader.path).to eq(uploaded_file.remote_id)
              expect(uploader.object_store).to eq(described_class::Store::REMOTE)

              expect(object.file_final_path).to eq(uploaded_file.remote_id)
            end

            context 'when bucket prefix is configured' do
              let(:fog_config) do
                Gitlab.config.uploads.object_store.tap do |config|
                  config[:remote_directory] = 'main-bucket'
                  config[:bucket_prefix] = 'my/uploads'
                end
              end

              let(:bucket) { 'main-bucket' }
              let(:fog_file_path) { "my/uploads/#{final_path}" }

              it 'stores the file final path in the db without the prefix' do
                expect { subject }.not_to raise_error

                expect(uploader.store_path).to eq("my/uploads/#{final_path}")
                expect(object.file_final_path).to eq(final_path)
              end

              context 'and file is stored' do
                subject do
                  uploader.store!(uploaded_file)
                end

                it 'completes the matching pending upload entry' do
                  expect { subject }
                    .to change { ObjectStorage::PendingDirectUpload.exists?(uploader_class.storage_location_identifier, final_path) }
                    .to(false)
                end
              end
            end

            context 'when file is stored' do
              subject do
                uploader.store!(uploaded_file)
              end

              it 'file to be remotely stored in permament location' do
                subject

                expect(uploader).to be_exists
                expect(uploader).not_to be_cached
                expect(uploader.path).to eq(uploaded_file.remote_id)
              end

              it 'does not trigger Carrierwave copy and delete because it is already in the final location' do
                expect_next_instance_of(CarrierWave::Storage::Fog::File) do |instance|
                  expect(instance).not_to receive(:copy_to)
                  expect(instance).not_to receive(:delete)
                end

                subject
              end
            end
          end
        end
      end
    end
  end

  describe '#retrieve_from_store!' do
    context 'uploaders that includes the RecordsUploads extension' do
      [:group, :project, :user].each do |model|
        context "for #{model}s" do
          let(:models) { create_list(model, 3, :with_avatar).map(&:reload) }
          let(:avatars) { models.map(&:avatar) }

          it 'batches fetching uploads from the database' do
            # Ensure that these are all created and fully loaded before we start
            # running queries for avatars
            models

            expect { avatars }.not_to exceed_query_limit(1)
          end

          it 'does not attempt to replace methods' do
            models.each do |model|
              expect(model.avatar.upload).to receive(:method_missing).and_call_original

              model.avatar.upload.path
            end
          end

          it 'fetches a unique upload for each model' do
            expect(avatars.map(&:url).uniq).to eq(avatars.map(&:url))
            expect(avatars.map(&:upload).uniq).to eq(avatars.map(&:upload))
          end
        end
      end
    end

    describe 'filename' do
      let(:model) { create(:ci_job_artifact, :remote_store, :archive) }

      before do
        stub_artifacts_object_storage
      end

      shared_examples 'ensuring correct filename' do
        it 'uses the original filename' do
          expect(model.reload.file.filename).to eq('ci_build_artifacts.zip')
        end
      end

      context 'when model has final path defined for the file column' do
        before do
          model.update_column(:file_final_path, 'some/final/path/abc-123')
        end

        it_behaves_like 'ensuring correct filename'
      end

      context 'when model has no final path defined for the file column' do
        it_behaves_like 'ensuring correct filename'
      end
    end
  end

  describe '#replace_file_without_saving!' do
    context 'when object storage and direct upload is enabled' do
      let(:upload_path) { 'some/path/123' }

      let!(:fog_connection) do
        stub_uploads_object_storage(uploader_class, enabled: true, direct_upload: true)
      end

      let!(:fog_file) do
        fog_connection.directories.new(key: 'uploads').files.create( # rubocop:disable Rails/SaveBang
          key: upload_path,
          body: 'old content'
        )
      end

      before do
        uploader.object_store = described_class::Store::REMOTE
      end

      # This scenario can happen when replicating object storage uploads.
      # See Geo::Replication::BlobDownloader#download_file
      # A SanitizedFile from a Tempfile will be passed to replace_file_without_saving!
      context 'and given file is not a CarrierWave::Storage::Fog::File' do
        let(:temp_file) { Tempfile.new("test") }
        let(:new_file) { CarrierWave::SanitizedFile.new(temp_file) }

        before do
          temp_file.write('new content')
          temp_file.close
          FileUtils.touch(temp_file)
          allow(object).to receive(:file_final_path).and_return(file_final_path)
        end

        after do
          FileUtils.rm_f(temp_file)
        end

        shared_examples 'skipping triggers for local file' do
          it 'allows file to be replaced without triggering any callbacks' do
            expect(uploader).not_to receive(:with_callbacks)

            uploader.replace_file_without_saving!(new_file)
          end

          it 'does not trigger pending upload checks' do
            expect(ObjectStorage::PendingDirectUpload).not_to receive(:complete)

            uploader.replace_file_without_saving!(new_file)
          end
        end

        context 'and uploader model has the file_final_path' do
          let(:file_final_path) { upload_path }

          it_behaves_like 'skipping triggers for local file'

          it 'uses default CarrierWave behavior and uploads the file to object storage using the final path' do
            uploader.replace_file_without_saving!(new_file)

            updated_content = fog_connection.directories.get('uploads').files.get(upload_path).body
            expect(updated_content).to eq('new content')
          end
        end

        context 'and uploader model has no file_final_path' do
          let(:file_final_path) { nil }

          it_behaves_like 'skipping triggers for local file'

          it 'uses default CarrierWave behavior and uploads the file to object storage using the uploader store path' do
            uploader.replace_file_without_saving!(new_file)

            content = fog_connection.directories.get('uploads').files.get(uploader.store_path).body
            expect(content).to eq('new content')
          end
        end
      end
    end
  end

  describe '.generate_final_store_path' do
    let(:root_hash) { 12345 }
    let(:expected_root_hashed_path) { Gitlab::HashedPath.new(root_hash: root_hash) }

    subject(:final_path) { uploader_class.generate_final_store_path(root_hash: root_hash) }

    before do
      allow(Digest::SHA2).to receive(:hexdigest).and_return('somehash1234')
    end

    it 'returns the generated hashed path nested under the hashed path of the root ID' do
      expect(final_path).to eq(File.join(expected_root_hashed_path, '@final/so/me/hash1234'))
    end
  end

  describe 'OpenFile' do
    subject { ObjectStorage::Concern::OpenFile.new(file) }

    let(:file) { double(read: true, size: true, path: true) }

    it 'delegates read and size methods' do
      expect(subject.read).to eq(true)
      expect(subject.size).to eq(true)
    end

    it 'does not delegate path method' do
      expect { subject.path }.to raise_error(NoMethodError)
    end
  end
end

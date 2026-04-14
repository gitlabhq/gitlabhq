# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CarrierWave::Storage::Fog::File', feature_category: :job_artifacts do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:storage) { CarrierWave::Storage::Fog.new(uploader) }
  let(:bucket_name) { 'some-bucket' }
  let(:connection) { ::Fog::Storage.new(connection_options) }
  let(:bucket) { connection.directories.new(key: bucket_name) }
  let(:test_filename) { 'test.txt' }
  let(:test_data) { 'test content' }

  subject(:fog_file) { CarrierWave::Storage::Fog::File.new(uploader, storage, test_filename) }

  before do
    stub_object_storage(connection_params: connection_options, remote_directory: bucket_name)

    allow(uploader).to receive_messages(
      fog_directory: bucket_name,
      fog_credentials: connection_options,
      fog_attributes: {},
      fog_public: nil
    )

    bucket.files.create(key: test_filename, body: test_data) # rubocop:disable Rails/SaveBang -- fog file collections do not use ActiveRecord
  end

  shared_examples 'no ACL header' do
    it 'returns no ACL header' do
      expect(fog_file.send(:acl_header)).to eq({})
    end
  end

  shared_examples 'no public attribute on store' do
    it 'does not pass :public to files.create' do
      sanitized_file = instance_double(CarrierWave::SanitizedFile,
        content_type: 'text/plain', to_file: nil, read: test_data)
      files = fog_file.send(:directory).files

      expect(files).to receive(:create) do |attrs|
        expect(attrs).not_to have_key(:public)
      end

      fog_file.store(sanitized_file)
    end
  end

  shared_examples 'passes public attribute on store' do |expected_value|
    it "passes public: #{expected_value.inspect} to files.create" do
      sanitized_file = instance_double(CarrierWave::SanitizedFile,
        content_type: 'text/plain', to_file: nil, read: test_data)
      files = fog_file.send(:directory).files

      expect(files).to receive(:create) do |attrs|
        expect(attrs[:public]).to eq(expected_value)
      end

      fog_file.store(sanitized_file)
    end
  end

  context 'with AWS provider' do
    let(:connection_options) do
      {
        provider: 'AWS',
        aws_access_key_id: 'ACCESS_KEY',
        aws_secret_access_key: 'SECRET_KEY'
      }
    end

    describe '#copy_to' do
      let(:dest_filename) { 'copied.txt' }

      it 'copies the file using multithreaded transfer' do
        inner_fog_file = fog_file.send(:file)

        expect(inner_fog_file).to receive(:concurrency=).with(10).and_call_original
        expect(inner_fog_file).to receive(:multipart_chunk_size=).with(10.megabytes).and_call_original
        expect(inner_fog_file).to receive(:copy).with(bucket_name, dest_filename, anything).and_call_original

        result = fog_file.copy_to(dest_filename)

        expect(result.exists?).to be true
        expect(result.read).to eq(test_data)
        copied = bucket.files.get(dest_filename)
        expect(copied).to be_present
        expect(copied.body).to eq(test_data)
      end

      context 'when fog_acl is false (ACLs disabled)' do
        before do
          allow(uploader).to receive(:fog_acl).and_return(false)
        end

        it 'does not include x-amz-acl in copy options' do
          expect(fog_file.send(:copy_to_options)).not_to have_key('x-amz-acl')
        end
      end

      context 'when fog_acl is nil (legacy behavior)' do
        before do
          allow(uploader).to receive(:fog_acl).and_return(nil)
        end

        it 'includes x-amz-acl: private in copy options when fog_public is nil' do
          expect(fog_file.send(:copy_to_options)['x-amz-acl']).to eq('private')
        end
      end
    end

    describe '#clean_cache!' do
      let(:cache_dir) { 'uploads/tmp' }

      before do
        allow(uploader).to receive(:cache_dir).and_return(cache_dir)
      end

      it 'removes files older than the given number of seconds and keeps newer ones' do
        allow(uploader).to receive(:fog_acl).and_return(false)

        old_key = "#{cache_dir}/#{(Time.now.utc - 2.hours).to_i}-0-0-0/file.txt"
        new_key = "#{cache_dir}/#{Time.now.utc.to_i}-0-0-0/file.txt"
        bucket.files.create(key: old_key, body: 'old') # rubocop:disable Rails/SaveBang -- fog file collections do not use ActiveRecord
        bucket.files.create(key: new_key, body: 'new') # rubocop:disable Rails/SaveBang -- fog file collections do not use ActiveRecord

        storage.clean_cache!(3600)

        expect(bucket.files.get(old_key)).to be_nil
        expect(bucket.files.get(new_key)).to be_present
      end

      context 'when fog_acl is false (ACLs disabled)' do
        before do
          allow(uploader).to receive(:fog_acl).and_return(false)
        end

        it 'does not access fog_public when listing the cache directory' do
          expect(uploader).not_to receive(:fog_public)

          storage.clean_cache!(3600)
        end
      end

      context 'when fog_acl is nil (legacy behavior)' do
        before do
          allow(uploader).to receive(:fog_acl).and_return(nil)
        end

        it 'passes :public when listing the cache directory' do
          storage.clean_cache!(3600)

          expect(uploader).to have_received(:fog_public)
        end
      end
    end

    context 'when fog_acl is false (ACLs disabled)' do
      before do
        allow(uploader).to receive(:fog_acl).and_return(false)
      end

      it_behaves_like 'no ACL header'
      it_behaves_like 'no public attribute on store'
    end

    context 'when fog_acl is nil (legacy behavior)' do
      before do
        allow(uploader).to receive(:fog_acl).and_return(nil)
      end

      it 'returns x-amz-acl: private when fog_public is nil' do
        expect(fog_file.send(:acl_header)).to eq({ 'x-amz-acl' => 'private' })
      end

      it 'returns x-amz-acl: public-read when fog_public is true' do
        allow(uploader).to receive(:fog_public).and_return(true)

        expect(fog_file.send(:acl_header)).to eq({ 'x-amz-acl' => 'public-read' })
      end

      it_behaves_like 'passes public attribute on store', nil
    end

    context 'when fog_acl is a custom string' do
      before do
        allow(uploader).to receive(:fog_acl).and_return('bucket-owner-full-control')
      end

      it 'returns the custom ACL value' do
        expect(fog_file.send(:acl_header)).to eq({ 'x-amz-acl' => 'bucket-owner-full-control' })
      end

      it_behaves_like 'no public attribute on store'
    end
  end

  context 'with Google provider' do
    let(:connection_options) do
      {
        provider: 'Google',
        google_storage_access_key_id: 'ACCESS_KEY',
        google_storage_secret_access_key: 'SECRET_KEY'
      }
    end

    context 'when fog_acl is false (ACLs disabled)' do
      before do
        allow(uploader).to receive(:fog_acl).and_return(false)
      end

      it_behaves_like 'no ACL header'
      it_behaves_like 'no public attribute on store'
    end

    context 'when fog_acl is nil (legacy behavior)' do
      before do
        allow(uploader).to receive(:fog_acl).and_return(nil)
      end

      # Preserves the original CarrierWave 1.3.4 behavior: acl_header returns {}
      # for non-AWS providers unless fog_acl is explicitly set to a string.
      it 'returns no ACL header regardless of fog_public' do
        expect(fog_file.send(:acl_header)).to eq({})
      end

      it 'returns no ACL header even when fog_public is true' do
        allow(uploader).to receive(:fog_public).and_return(true)

        expect(fog_file.send(:acl_header)).to eq({})
      end

      it_behaves_like 'passes public attribute on store', nil
    end

    context 'when fog_acl is a custom string' do
      before do
        allow(uploader).to receive(:fog_acl).and_return('projectPrivate')
      end

      it 'returns the custom ACL as destination_predefined_acl' do
        expect(fog_file.send(:acl_header)).to eq({ destination_predefined_acl: 'projectPrivate' })
      end

      it_behaves_like 'no public attribute on store'
    end
  end

  context 'with Azure provider' do
    let(:connection_options) do
      {
        provider: 'AzureRM',
        azure_storage_account_name: 'AZURE_ACCOUNT_NAME',
        azure_storage_access_key: 'AZURE_ACCESS_KEY'
      }
    end

    describe '#copy_to' do
      let(:dest_filename) { 'copied.txt' }

      it 'copies the file' do
        result = fog_file.copy_to(dest_filename)

        # Fog Azure provider doesn't mock the actual copied data
        expect(result.exists?).to be true
      end
    end

    describe '#authenticated_url' do
      let(:expire_at) { 24.hours.from_now }
      let(:options) { { expire_at: expire_at } }

      it 'returns an authenticated URL' do
        expect(fog_file.authenticated_url(options))
          .to eq("https://mockaccount.blob.core.windows.net/test_container/test_blob?token")
      end

      context 'with custom expire_at' do
        it 'passes expire_at to the fog file url method' do
          expect_next_instance_of(Fog::AzureRM::Storage::File) do |file|
            expect(file).to receive(:url).with(expire_at, options).and_call_original
          end

          expect(fog_file.authenticated_url(options))
            .to eq("https://mockaccount.blob.core.windows.net/test_container/test_blob?token")
        end
      end

      context 'with content_disposition option' do
        let(:options) { { expire_at: expire_at, content_disposition: 'attachment' } }

        it 'passes content_disposition to the fog file url method' do
          expect_next_instance_of(Fog::AzureRM::Storage::File) do |file|
            expect(file).to receive(:url).with(expire_at, options).and_call_original
          end

          expect(fog_file.authenticated_url(options))
            .to eq("https://mockaccount.blob.core.windows.net/test_container/test_blob?token")
        end
      end
    end

    context 'when fog_acl is false' do
      before do
        allow(uploader).to receive(:fog_acl).and_return(false)
      end

      it_behaves_like 'no ACL header'
    end

    context 'when fog_acl is a custom string' do
      before do
        allow(uploader).to receive(:fog_acl).and_return('some-value')
      end

      it_behaves_like 'no ACL header'
    end
  end
end

RSpec.describe 'ObjectStorage uploader', feature_category: :job_artifacts do
  let(:uploader_class) do
    Class.new(GitlabUploader) do
      include ObjectStorage::Concern
    end
  end

  let(:uploader) { uploader_class.new(build_stubbed(:user), :avatar) }

  describe '#fog_acl' do
    it 'returns false to disable ACL headers on object storage' do
      expect(uploader.fog_acl).to be(false)
    end
  end

  describe '#fog_public' do
    it 'returns nil' do
      expect(uploader.fog_public).to be_nil
    end
  end
end

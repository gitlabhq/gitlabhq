# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FileUploader do
  let(:group) { create(:group, path: 'awesome') }
  let(:project) { create(:project, :legacy_storage, namespace: group, path: 'project') }
  let(:uploader) { described_class.new(project, :avatar) }
  let(:upload) { double(model: project, path: "#{secret}/foo.jpg") }
  let(:secret) { "55dc16aa0edd05693fd98b5051e83321" } # this would be nicer as SecureRandom.hex, but the shared_examples breaks

  subject { uploader }

  shared_examples 'builds correct legacy storage paths' do
    include_examples 'builds correct paths',
      store_dir: %r{awesome/project/\h+},
      upload_path: %r{\h+/<filename>},
      absolute_path: %r{#{described_class.root}/awesome/project/55dc16aa0edd05693fd98b5051e83321/foo.jpg}
  end

  context 'legacy storage' do
    it_behaves_like 'builds correct legacy storage paths'

    context 'uses hashed storage' do
      context 'when rolled out attachments' do
        let(:project) { build_stubbed(:project, namespace: group, path: 'project') }

        include_examples 'builds correct paths',
          store_dir: %r{@hashed/\h{2}/\h{2}/\h+},
          upload_path: %r{\h+/<filename>}
      end

      context 'when only repositories are rolled out' do
        let(:project) { build_stubbed(:project, namespace: group, path: 'project', storage_version: Project::HASHED_STORAGE_FEATURES[:repository]) }

        it_behaves_like 'builds correct legacy storage paths'
      end
    end
  end

  context 'object store is remote' do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    # always use hashed storage path for remote uploads
    it_behaves_like 'builds correct paths',
      store_dir: %r{@hashed/\h{2}/\h{2}/\h+},
      upload_path: %r{@hashed/\h{2}/\h{2}/\h+/\h+/<filename>}
  end

  describe 'initialize' do
    let(:uploader) { described_class.new(double, secret: secret) }

    it 'accepts a secret parameter' do
      expect(described_class).not_to receive(:generate_secret)
      expect(uploader.secret).to eq(secret)
    end
  end

  describe 'callbacks' do
    describe '#prune_store_dir after :remove' do
      before do
        uploader.store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
      end

      def store_dir
        File.expand_path(uploader.store_dir, uploader.root)
      end

      it 'is called' do
        expect(uploader).to receive(:prune_store_dir).once

        uploader.remove!
      end

      it 'prune the store directory' do
        expect { uploader.remove! }
          .to change { File.exist?(store_dir) }.from(true).to(false)
      end
    end
  end

  describe 'copy_to' do
    let(:new_project) { create(:project) }
    let(:moved) { described_class.copy_to(subject, new_project) }

    shared_examples 'returns a valid uploader' do
      describe 'returned uploader' do
        it 'generates a new secret' do
          expect(subject).to be_present
          expect(described_class).to receive(:generate_secret).once.and_call_original
          expect(moved).to be_present
        end

        it 'creates new upload correctly' do
          upload = moved.upload

          expect(upload).not_to eq(subject.upload)
          expect(upload.model).to eq(new_project)
          expect(upload.uploader).to eq('FileUploader')
          expect(upload.secret).not_to eq(subject.upload.secret)
        end

        it 'copies the file' do
          expect(subject.file).to exist
          expect(moved.file).to exist
          expect(subject.file).not_to eq(moved.file)
          expect(subject.object_store).to eq(moved.object_store)
        end
      end
    end

    context 'files are stored locally' do
      before do
        subject.store!(fixture_file_upload('spec/fixtures/dk.png'))
      end

      include_examples 'returns a valid uploader'

      it 'copies the file to the correct location' do
        expect(moved.upload.path).to eq("#{moved.upload.secret}/dk.png")
        expect(moved.file.path).to end_with("public/uploads/#{new_project.disk_path}/#{moved.upload.secret}/dk.png")
        expect(moved.filename).to eq('dk.png')
      end
    end

    context 'files are stored remotely' do
      before do
        stub_uploads_object_storage
        subject.store!(fixture_file_upload('spec/fixtures/dk.png'))
        subject.migrate!(ObjectStorage::Store::REMOTE)
      end

      include_examples 'returns a valid uploader'

      it 'copies the file to the correct location' do
        expect(moved.upload.path).to eq("#{new_project.disk_path}/#{moved.upload.secret}/dk.png")
        expect(moved.file.path).to eq("#{new_project.disk_path}/#{moved.upload.secret}/dk.png")
        expect(moved.filename).to eq('dk.png')
      end
    end
  end

  describe '.extract_dynamic_path' do
    shared_examples 'a valid secret' do |root_path|
      context 'with a 32-byte hexadecimal secret' do
        let(:secret) { SecureRandom.hex }
        let(:path) { File.join(*[root_path, secret, 'dummy.txt'].compact) }

        it 'extracts the secret' do
          expect(described_class.extract_dynamic_path(path)[:secret]).to eq(secret)
        end

        it 'extracts the identifier' do
          expect(described_class.extract_dynamic_path(path)[:identifier]).to eq('dummy.txt')
        end
      end

      context 'with a 10-byte hexadecimal secret' do
        let(:secret) { SecureRandom.hex[0, 10] }
        let(:path) { File.join(*[root_path, secret, 'dummy.txt'].compact) }

        it 'extracts the secret' do
          expect(described_class.extract_dynamic_path(path)[:secret]).to eq(secret)
        end

        it 'extracts the identifier' do
          expect(described_class.extract_dynamic_path(path)[:identifier]).to eq('dummy.txt')
        end
      end

      context 'with an invalid secret' do
        let(:secret) { 'foo' }
        let(:path) { File.join(*[root_path, secret, 'dummy.txt'].compact) }

        it 'returns nil' do
          expect(described_class.extract_dynamic_path(path)).to be_nil
        end
      end
    end

    context 'with an absolute path without a slash in the beginning' do
      it_behaves_like 'a valid secret', 'export/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/test/uploads'
    end

    context 'with an absolute path with a slash in the beginning' do
      it_behaves_like 'a valid secret', '/export/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/test/uploads'
    end

    context 'with an relative path without a slash in the beginning' do
      it_behaves_like 'a valid secret', nil
    end

    context 'with an relative path with a slash in the beginning' do
      it_behaves_like 'a valid secret', '/'
    end
  end

  describe '#secret' do
    it 'generates a secret if none is provided' do
      expect(described_class).to receive(:generate_secret).and_return(secret)
      expect(uploader.secret).to eq(secret)
      expect(uploader.secret.size).to eq(32)
    end

    context "validation" do
      before do
        uploader.instance_variable_set(:@secret, secret)
      end

      context "32-byte hexadecimal" do
        let(:secret) { SecureRandom.hex }

        it "returns the secret" do
          expect(uploader.secret).to eq(secret)
        end
      end

      context "10-byte hexadecimal" do
        let(:secret) { SecureRandom.hex[0, 10] }

        it "returns the secret" do
          expect(uploader.secret).to eq(secret)
        end
      end

      context "invalid secret supplied" do
        let(:secret) { "%2E%2E%2F%2E%2E%2F%2E%2E%2F%2E%2E%2F%2E%2E%2F%2E%2E%2F%2E%2E%2Fgrafana%2Fconf%2F" }

        it "raises an exception" do
          expect { uploader.secret }.to raise_error(described_class::InvalidSecret)
        end
      end
    end
  end

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload('spec/fixtures/dk.png'))
      stub_uploads_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end

  describe '#upload=' do
    let(:secret) { SecureRandom.hex }
    let(:upload) { create(:upload, :issuable_upload, secret: secret, filename: 'file.txt') }

    it 'handles nil' do
      expect(uploader).not_to receive(:apply_context!)

      uploader.upload = nil
    end

    it 'extract the uploader context from it' do
      expect(uploader).to receive(:apply_context!).with(a_hash_including(secret: secret, identifier: 'file.txt'))

      uploader.upload = upload
    end
  end

  describe '#replace_file_without_saving!' do
    let(:replacement) { Tempfile.create('replacement.jpg') }

    it 'replaces an existing file without changing its metadata' do
      expect { subject.replace_file_without_saving! CarrierWave::SanitizedFile.new(replacement) }.not_to change { subject.upload }
    end
  end

  context 'when remote file is used' do
    let(:temp_file) { Tempfile.new("test") }

    let!(:fog_connection) do
      stub_uploads_object_storage(described_class)
    end

    let(:filename) { "my file.txt" }
    let(:uploaded_file) do
      UploadedFile.new(temp_file.path, filename: filename, remote_id: "test/123123")
    end

    let!(:fog_file) do
      fog_connection.directories.new(key: 'uploads').files.create( # rubocop:disable Rails/SaveBang
        key: 'tmp/uploads/test/123123',
        body: 'content'
      )
    end

    before do
      FileUtils.touch(temp_file)

      uploader.store!(uploaded_file)
    end

    after do
      FileUtils.rm_f(temp_file)
    end

    describe '#cache!' do
      it 'file is stored remotely in permament location with sanitized name' do
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

    describe '#to_h' do
      subject { uploader.to_h }

      let(:filename) { 'my+file.txt' }

      it 'generates URL using original file name instead of filename returned by object storage' do
        # GCS returns a URL with a `+` instead of `%2B`
        allow(uploader.file).to receive(:url).and_return('https://storage.googleapis.com/gitlab-test-uploads/@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b/64c5065e62100b1a12841644256a98be/my+file.txt')

        expect(subject[:url]).to end_with(filename)
      end
    end
  end
end

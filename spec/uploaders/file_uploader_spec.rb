require 'spec_helper'

describe FileUploader do
  let(:group) { create(:group, name: 'awesome') }
  let(:project) { create(:project, :legacy_storage, namespace: group, name: 'project') }
  let(:uploader) { described_class.new(project) }
  let(:upload)  { double(model: project, path: 'secret/foo.jpg') }

  subject { uploader }

  shared_examples 'builds correct legacy storage paths' do
    include_examples 'builds correct paths',
                     store_dir: %r{awesome/project/\h+},
                     upload_path: %r{\h+/<filename>},
                     absolute_path: %r{#{described_class.root}/awesome/project/secret/foo.jpg}
  end

  context 'legacy storage' do
    it_behaves_like 'builds correct legacy storage paths'

    context 'uses hashed storage' do
      context 'when rolled out attachments' do
        let(:project) { build_stubbed(:project, namespace: group, name: 'project') }

        include_examples 'builds correct paths',
                         store_dir: %r{@hashed/\h{2}/\h{2}/\h+},
                         upload_path: %r{\h+/<filename>}
      end

      context 'when only repositories are rolled out' do
        let(:project) { build_stubbed(:project, namespace: group, name: 'project', storage_version: Project::HASHED_STORAGE_FEATURES[:repository]) }

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
    let(:uploader) { described_class.new(double, secret: 'secret') }

    it 'accepts a secret parameter' do
      expect(described_class).not_to receive(:generate_secret)
      expect(uploader.secret).to eq('secret')
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
    shared_examples 'returns a valid uploader' do
      describe 'returned uploader' do
        let(:new_project) { create(:project) }
        let(:moved) { described_class.copy_to(subject, new_project) }

        it 'generates a new secret' do
          expect(subject).to be
          expect(described_class).to receive(:generate_secret).once.and_call_original
          expect(moved).to be
        end

        it 'create new upload' do
          expect(moved.upload).not_to eq(subject.upload)
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
    end

    context 'files are stored remotely' do
      before do
        stub_uploads_object_storage
        subject.store!(fixture_file_upload('spec/fixtures/dk.png'))
        subject.migrate!(ObjectStorage::Store::REMOTE)
      end

      include_examples 'returns a valid uploader'
    end
  end

  describe '.extract_dynamic_path' do
    it 'works with hashed storage' do
      path = 'export/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/test/uploads/72a497a02fe3ee09edae2ed06d390038/dummy.txt'

      expect(described_class.extract_dynamic_path(path)[:identifier]).to eq('dummy.txt')
      expect(described_class.extract_dynamic_path(path)[:secret]).to eq('72a497a02fe3ee09edae2ed06d390038')
    end
  end

  describe '#secret' do
    it 'generates a secret if none is provided' do
      expect(described_class).to receive(:generate_secret).and_return('secret')
      expect(uploader.secret).to eq('secret')
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

  describe '#cache!' do
    subject do
      uploader.store!(uploaded_file)
    end

    context 'when remote file is used' do
      let(:temp_file) { Tempfile.new("test") }

      let!(:fog_connection) do
        stub_uploads_object_storage(described_class)
      end

      let(:uploaded_file) do
        UploadedFile.new(temp_file.path, filename: "my file.txt", remote_id: "test/123123")
      end

      let!(:fog_file) do
        fog_connection.directories.get('uploads').files.create(
          key: 'tmp/uploads/test/123123',
          body: 'content'
        )
      end

      before do
        FileUtils.touch(temp_file)
      end

      after do
        FileUtils.rm_f(temp_file)
      end

      it 'file is stored remotely in permament location with sanitized name' do
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
  end
end

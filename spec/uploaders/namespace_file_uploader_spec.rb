# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceFileUploader do
  let(:group) { build_stubbed(:group) }
  let(:uploader) { described_class.new(group) }
  let(:upload) { create(:upload, :namespace_upload, model: group) }
  let(:identifier) { %r{\h+/\S+} }

  subject { uploader }

  it_behaves_like 'builds correct paths' do
    let(:patterns) do
      {
        store_dir: %r{uploads/-/system/namespace/\d+},
        upload_path: identifier,
        absolute_path: %r{#{CarrierWave.root}/uploads/-/system/namespace/\d+/#{identifier}}
      }
    end
  end

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths' do
      let(:patterns) do
        {
          store_dir: %r{namespace/\d+/\h+},
          upload_path: identifier
        }
      end
    end
  end

  describe '.base_dir' do
    it 'returns local storage base_dir without store param' do
      expect(described_class.base_dir(group)).to eq("uploads/-/system/namespace/#{group.id}")
    end

    it 'returns local storage base_dir when store param is Store::LOCAL' do
      expect(described_class.base_dir(group, ObjectStorage::Store::LOCAL)).to eq("uploads/-/system/namespace/#{group.id}")
    end

    it 'returns remote base_dir when store param is Store::REMOTE' do
      expect(described_class.base_dir(group, ObjectStorage::Store::REMOTE)).to eq("namespace/#{group.id}")
    end
  end

  describe '#workhorse_local_upload_path' do
    it 'returns the correct path in uploads directory' do
      expect(described_class.workhorse_local_upload_path).to end_with('/uploads/tmp/uploads')
    end
  end

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload(File.join('spec/fixtures/doc_sample.txt')))
      stub_uploads_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end

  describe 'copy_to' do
    let(:group) { create(:group) }
    let(:moved) { described_class.copy_to(subject, group) }

    shared_examples 'returns a valid uploader' do
      it 'generates a new secret' do
        expect(subject).to be_present
        expect(described_class).to receive(:generate_secret).once.and_call_original
        expect(moved).to be_present
      end

      it 'creates new upload correctly' do
        upload = moved.upload

        expect(upload).not_to eq(subject.upload)
        expect(upload.model).to eq(group)
        expect(upload.uploader).to eq('NamespaceFileUploader')
        expect(upload.secret).not_to eq(subject.upload.secret)
      end

      it 'copies the file' do
        expect(subject.file).to exist
        expect(moved.file).to exist
        expect(subject.file).not_to eq(moved.file)
        expect(subject.object_store).to eq(moved.object_store)
      end
    end

    context 'files are stored locally' do
      before do
        subject.store!(fixture_file_upload('spec/fixtures/dk.png'))
      end

      include_examples 'returns a valid uploader'

      it 'copies the file to the correct location' do
        expect(moved.upload.path).to eq("#{moved.upload.secret}/dk.png")
        expect(moved.file.path).to end_with("system/namespace/#{group.id}/#{moved.upload.secret}/dk.png")
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
        expect(moved.file.path).to eq("namespace/#{group.id}/#{moved.upload.secret}/dk.png")
        expect(moved.filename).to eq('dk.png')
      end
    end
  end
end

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
                     absolute_path: %r{#{described_class.root}/awesome/project/secret/foo.jpg}
  end

  shared_examples 'uses hashed storage' do
    context 'when rolled out attachments' do
      let(:project) { build_stubbed(:project, namespace: group, name: 'project') }

      before do
        allow(project).to receive(:disk_path).and_return('ca/fe/fe/ed')
      end

      it_behaves_like 'builds correct paths',
                      store_dir: %r{ca/fe/fe/ed/\h+},
                      absolute_path: %r{#{described_class.root}/ca/fe/fe/ed/secret/foo.jpg}
    end

    context 'when only repositories are rolled out' do
      let(:project) { build_stubbed(:project, namespace: group, name: 'project', storage_version: Project::HASHED_STORAGE_FEATURES[:repository]) }

      it_behaves_like 'builds correct legacy storage paths'
    end
  end

  context 'legacy storage' do
    it_behaves_like 'builds correct legacy storage paths'
    include_examples 'uses hashed storage'
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

  describe '#secret' do
    it 'generates a secret if none is provided' do
      expect(described_class).to receive(:generate_secret).and_return('secret')
      expect(uploader.secret).to eq('secret')
    end
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

    context 'uploader_context is empty' do
      it 'fallbacks to regex based extraction' do
        expect(upload).to receive(:uploader_context).and_return({})

        uploader.upload = upload
        expect(uploader.secret).to eq(secret)
        expect(uploader.instance_variable_get(:@identifier)).to eq('file.txt')
      end
    end
  end
end

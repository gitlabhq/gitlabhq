require 'spec_helper'

describe FileUploader do
  let(:group) { create(:group, name: 'awesome') }
  let(:project) { create(:project, namespace: group, name: 'project') }
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
      before do
        allow(project).to receive(:disk_path).and_return('ca/fe/fe/ed')
      end

      let(:project) { build_stubbed(:project, :hashed, namespace: group, name: 'project') }

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
    let(:uploader) { described_class.new(double, 'secret') }

    it 'accepts a secret parameter' do
      expect(described_class).not_to receive(:generate_secret)
      expect(uploader.secret).to eq('secret')
    end
  end

  describe '#secret' do
    it 'generates a secret if none is provided' do
      expect(described_class).to receive(:generate_secret).and_return('secret')
      expect(uploader.secret).to eq('secret')
    end
  end
end

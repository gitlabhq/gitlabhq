require 'spec_helper'

describe ::Gitlab::RepoPath do
  describe '.strip_storage_path' do
    before do
      allow(Gitlab.config.repositories).to receive(:storages).and_return({
        'storage1' => { 'path' => '/foo' },
        'storage2' => { 'path' => '/bar' },
      })
    end

    it 'strips the storage path' do
      expect(described_class.strip_storage_path('/bar/foo/qux/baz.git')).to eq('foo/qux/baz.git')
    end

    it 'raises NotFoundError if no storage matches the path' do
      expect { described_class.strip_storage_path('/doesnotexist/foo.git') }.to raise_error(
        described_class::NotFoundError
      )
    end
  end
end

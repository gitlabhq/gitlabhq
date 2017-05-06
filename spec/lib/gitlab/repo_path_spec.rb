require 'spec_helper'

describe ::Gitlab::RepoPath do
  describe '.parse' do
    set(:project) { create(:project) }

    it 'parses a full repository path' do
      expect(described_class.parse(project.repository.path)).to eq([project, false])
    end

    it 'parses a full wiki path' do
      expect(described_class.parse(project.wiki.repository.path)).to eq([project, true])
    end

    it 'parses a relative repository path' do
      expect(described_class.parse(project.full_path + '.git')).to eq([project, false])
    end

    it 'parses a relative wiki path' do
      expect(described_class.parse(project.full_path + '.wiki.git')).to eq([project, true])
    end

    it 'parses a relative path starting with /' do
      expect(described_class.parse('/' + project.full_path + '.git')).to eq([project, false])
    end
  end

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

require 'spec_helper'

describe ::Gitlab::BareRepositoryImport::Repository do
  let(:project_repo_path) { described_class.new('/full/path/', '/full/path/to/repo.git') }

  it 'stores the repo path' do
    expect(project_repo_path.repo_path).to eq('/full/path/to/repo.git')
  end

  it 'stores the group path' do
    expect(project_repo_path.group_path).to eq('to')
  end

  it 'stores the project name' do
    expect(project_repo_path.project_name).to eq('repo')
  end

  it 'stores the wiki path' do
    expect(project_repo_path.wiki_path).to eq('/full/path/to/repo.wiki.git')
  end

  describe '#wiki?' do
    it 'returns true if it is a wiki' do
      wiki_path = described_class.new('/full/path/', '/full/path/to/a/b/my.wiki.git')

      expect(wiki_path.wiki?).to eq(true)
    end

    it 'returns false if it is not a wiki' do
      expect(project_repo_path.wiki?).to eq(false)
    end
  end

  describe '#hashed?' do
    it 'returns true if it is a hashed folder' do
      path = described_class.new('/full/path/', '/full/path/@hashed/my.repo.git')

      expect(path.hashed?).to eq(true)
    end

    it 'returns false if it is not a hashed folder' do
      expect(project_repo_path.hashed?).to eq(false)
    end
  end

  describe '#project_full_path' do
    it 'returns the project full path' do
      expect(project_repo_path.repo_path).to eq('/full/path/to/repo.git')
    end
  end
end

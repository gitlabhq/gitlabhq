require 'spec_helper'

describe ::Gitlab::ProjectRepoPath do
  let(:project_repo_path) { described_class.new('/full/path', '/full/path/to/repo.git') }

  it 'stores the repo path' do
    expect(project_repo_path.repo_path).to eq('/full/path/to/repo.git')
  end

  it 'stores the group path' do
    expect(project_repo_path.group_path).to eq('to')
  end

  it 'stores the project name' do
    expect(project_repo_path.project_name).to eq('repo')
  end

  describe '#wiki?' do
    it 'returns true if it is a wiki' do
      wiki_path = described_class.new('/full/path', '/full/path/to/my.wiki.git')

      expect(wiki_path.wiki?).to eq(true)
    end

    it 'returns false if it is not a wiki' do
      expect(project_repo_path.wiki?).to eq(false)
    end
  end

  describe '#project_full_path' do
    it 'returns the project full path' do
      expect(project_repo_path.repo_path).to eq('/full/path/to/repo.git')
    end
  end
end

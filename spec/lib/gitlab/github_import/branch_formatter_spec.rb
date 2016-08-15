require 'spec_helper'

describe Gitlab::GithubImport::BranchFormatter, lib: true do
  let(:project) { create(:project) }
  let(:commit) { create(:commit, project: project) }
  let(:repo) { double }
  let(:raw) do
    {
      ref: 'feature',
      repo: repo,
      sha: commit.id
    }
  end

  describe '#exists?' do
    it 'returns true when both branch, and commit exists' do
      branch = described_class.new(project, double(raw))

      expect(branch.exists?).to eq true
    end

    it 'returns false when branch does not exist' do
      branch = described_class.new(project, double(raw.merge(ref: 'removed-branch')))

      expect(branch.exists?).to eq false
    end

    it 'returns false when commit does not exist' do
      branch = described_class.new(project, double(raw.merge(sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b')))

      expect(branch.exists?).to eq false
    end
  end

  describe '#repo' do
    it 'returns raw repo' do
      branch = described_class.new(project, double(raw))

      expect(branch.repo).to eq repo
    end
  end

  describe '#sha' do
    it 'returns raw sha' do
      branch = described_class.new(project, double(raw))

      expect(branch.sha).to eq commit.id
    end
  end

  describe '#valid?' do
    it 'returns true when raw repo is present' do
      branch = described_class.new(project, double(raw))

      expect(branch.valid?).to eq true
    end

    it 'returns false when raw repo is blank' do
      branch = described_class.new(project, double(raw.merge(repo: nil)))

      expect(branch.valid?).to eq false
    end
  end
end

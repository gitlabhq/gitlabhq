# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::LegacyGithubImport::BranchFormatter do
  let(:project) { create(:project, :repository) }
  let(:commit) { create(:commit, project: project) }
  let(:repo) { double }
  let(:raw) do
    {
      ref: 'branch-merged',
      repo: repo,
      sha: commit.id
    }
  end

  describe '#exists?' do
    it 'returns true when branch exists and commit is part of the branch' do
      branch = described_class.new(project, double(raw))

      expect(branch.exists?).to eq true
    end

    it 'returns false when branch exists and commit is not part of the branch' do
      branch = described_class.new(project, double(raw.merge(ref: 'feature')))

      expect(branch.exists?).to eq false
    end

    it 'returns false when branch does not exist' do
      branch = described_class.new(project, double(raw.merge(ref: 'removed-branch')))

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
    it 'returns true when raw sha and ref are present' do
      branch = described_class.new(project, double(raw))

      expect(branch.valid?).to eq true
    end

    it 'returns false when raw sha is blank' do
      branch = described_class.new(project, double(raw.merge(sha: nil)))

      expect(branch.valid?).to eq false
    end

    it 'returns false when raw ref is blank' do
      branch = described_class.new(project, double(raw.merge(ref: nil)))

      expect(branch.valid?).to eq false
    end
  end
end

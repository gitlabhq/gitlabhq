# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::DivergingCommitCountsService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe '#call' do
    let(:diverged_branch) { repository.find_branch('fix') }
    let(:root_ref_sha) { repository.raw_repository.commit(repository.root_ref).id }
    let(:diverged_branch_sha) { diverged_branch.target }

    let(:service) { described_class.new(repository) }

    it 'returns the commit counts behind and ahead of default branch' do
      result = service.call(diverged_branch)

      expect(result).to eq(behind: 29, ahead: 2)
    end

    it 'calls diverging_commit_count with default max count' do
      expect(repository.raw_repository)
        .to receive(:diverging_commit_count)
        .with(root_ref_sha, diverged_branch_sha, max_count: 0)
        .and_return([29, 2])

      service.call(diverged_branch)
    end
  end

  describe '#diverging_counts' do
    let(:service) { described_class.new(repository) }
    let(:from_sha) { repository.commit('master').sha }
    let(:to_sha) { repository.commit('fix').sha }

    it 'returns the commit counts behind and ahead' do
      result = service.diverging_counts(from_sha, to_sha)

      expect(result).to match(behind: a_kind_of(Integer), ahead: a_kind_of(Integer))
    end

    it 'passes max_count through to the repository' do
      expect(repository.raw_repository)
        .to receive(:diverging_commit_count)
        .with(from_sha, to_sha, max_count: 100)
        .and_return([1, 2])

      service.diverging_counts(from_sha, to_sha, max_count: 100)
    end
  end
end

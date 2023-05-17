# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::DivergingCommitCountsService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe '#call' do
    let(:diverged_branch) { repository.find_branch('fix') }
    let(:root_ref_sha) { repository.raw_repository.commit(repository.root_ref).id }
    let(:diverged_branch_sha) { diverged_branch.dereferenced_target.sha }

    let(:service) { described_class.new(repository) }

    it 'returns the commit counts behind and ahead of default branch' do
      result = service.call(diverged_branch)

      expect(result).to eq(behind: 29, ahead: 2)
    end

    it 'calls diverging_commit_count without max count' do
      expect(repository.raw_repository)
        .to receive(:diverging_commit_count)
        .with(root_ref_sha, diverged_branch_sha)
        .and_return([29, 2])

      service.call(diverged_branch)
    end
  end
end

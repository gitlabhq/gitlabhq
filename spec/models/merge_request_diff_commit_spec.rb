require 'rails_helper'

describe MergeRequestDiffCommit do
  let(:merge_request) { create(:merge_request) }
  subject { merge_request.commits.first }

  describe '#to_hash' do
    it 'returns the same results as Commit#to_hash, except for parent_ids' do
      commit_from_repo = merge_request.project.repository.commit(subject.sha)
      commit_from_repo_hash = commit_from_repo.to_hash.merge(parent_ids: [])

      expect(subject.to_hash).to eq(commit_from_repo_hash)
    end
  end
end

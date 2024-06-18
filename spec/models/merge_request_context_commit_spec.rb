# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestContextCommit, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:raw_repository) { project.repository.raw_repository }
  let(:commits) do
    [
      project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e'),
      project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
    ]
  end

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to have_many(:diff_files).class_name("MergeRequestContextCommitDiffFile") }
  end

  describe 'validations' do
    it 'validates merge_request_id presence' do
      expect(described_class.new).to validate_presence_of(:merge_request_id)
    end
  end

  describe '.delete_bulk' do
    let(:context_commit1) { create(:merge_request_context_commit, merge_request: merge_request, sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    let(:context_commit2) { create(:merge_request_context_commit, merge_request: merge_request, sha: '570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }

    it 'deletes context commits for given commit sha\'s and returns the commit' do
      expect(described_class.delete_bulk(merge_request, [context_commit1, context_commit2])).to eq(2)
    end

    it 'doesn\'t delete context commits when commit sha\'s are not passed' do
      expect(described_class.delete_bulk(merge_request, [])).to eq(0)
    end
  end
end

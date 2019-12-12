# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BranchPushMergeCommitAnalyzer do
  let(:project) { create(:project, :repository) }
  let(:oldrev) { 'merge-commit-analyze-before' }
  let(:newrev) { 'merge-commit-analyze-after' }
  let(:commits) { project.repository.commits_between(oldrev, newrev).reverse }

  subject { described_class.new(commits) }

  describe '#get_merge_commit' do
    let(:expected_merge_commits) do
      {
        '646ece5cfed840eca0a4feb21bcd6a81bb19bda3' => '646ece5cfed840eca0a4feb21bcd6a81bb19bda3',
        '29284d9bcc350bcae005872d0be6edd016e2efb5' => '29284d9bcc350bcae005872d0be6edd016e2efb5',
        '5f82584f0a907f3b30cfce5bb8df371454a90051' => '29284d9bcc350bcae005872d0be6edd016e2efb5',
        '8a994512e8c8f0dfcf22bb16df6e876be7a61036' => '29284d9bcc350bcae005872d0be6edd016e2efb5',
        '689600b91aabec706e657e38ea706ece1ee8268f' => '29284d9bcc350bcae005872d0be6edd016e2efb5',
        'db46a1c5a5e474aa169b6cdb7a522d891bc4c5f9' => 'db46a1c5a5e474aa169b6cdb7a522d891bc4c5f9'
      }
    end

    it 'returns correct merge commit SHA for each commit' do
      expected_merge_commits.each do |commit, merge_commit|
        expect(subject.get_merge_commit(commit)).to eq(merge_commit)
      end
    end

    context 'when one parent has two children' do
      let(:oldrev) { '1adbdefe31288f3bbe4b614853de4908a0b6f792' }
      let(:newrev) { '5f82584f0a907f3b30cfce5bb8df371454a90051' }

      let(:expected_merge_commits) do
        {
          '5f82584f0a907f3b30cfce5bb8df371454a90051' => '5f82584f0a907f3b30cfce5bb8df371454a90051',
          '8a994512e8c8f0dfcf22bb16df6e876be7a61036' => '5f82584f0a907f3b30cfce5bb8df371454a90051',
          '689600b91aabec706e657e38ea706ece1ee8268f' => '689600b91aabec706e657e38ea706ece1ee8268f'
        }
      end

      it 'returns correct merge commit SHA for each commit' do
        expected_merge_commits.each do |commit, merge_commit|
          expect(subject.get_merge_commit(commit)).to eq(merge_commit)
        end
      end
    end

    context 'when relevant_commit_ids is provided' do
      let(:relevant_commit_id) { '8a994512e8c8f0dfcf22bb16df6e876be7a61036' }

      subject { described_class.new(commits, relevant_commit_ids: [relevant_commit_id]) }

      it 'returns correct merge commit' do
        expected_merge_commits.each do |commit, merge_commit|
          subject = described_class.new(commits, relevant_commit_ids: [commit])
          expect(subject.get_merge_commit(commit)).to eq(merge_commit)
        end
      end
    end
  end
end

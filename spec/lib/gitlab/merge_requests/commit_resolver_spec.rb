# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::CommitResolver, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }

  let(:commit_id) { merge_request.commit_shas.first }

  subject(:resolve) { described_class.new(merge_request, commit_id).resolve }

  describe '#resolve' do
    context 'when commit_id is blank' do
      let(:commit_id) { '' }

      it { is_expected.to be_nil }
    end

    context 'when commit_id belongs to the merge request' do
      it 'returns the commit' do
        expect(resolve).to eq(project.commit(commit_id))
      end
    end

    context 'when commit_id is a context commit' do
      let(:context_commit_sha) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
      let(:commit_id) { context_commit_sha }

      before do
        create(:merge_request_context_commit, merge_request: merge_request, sha: context_commit_sha)
      end

      it 'returns the commit', :aggregate_failures do
        commit = project.commit(context_commit_sha)
        expect(commit).not_to be_nil
        expect(resolve).to eq(commit)
      end
    end

    context 'when commit_id does not belong to the merge request' do
      let(:commit_id) { 'abc123' }

      it { is_expected.to be_nil }
    end

    context 'when the commit belongs to the merge request but is missing from the repository' do
      before do
        allow(merge_request).to receive(:commit_exists?).with(commit_id).and_return(true)
        allow(merge_request.project).to receive(:commit).with(commit_id).and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end
end

require 'spec_helper'

describe RebaseWorker, '#perform' do
  context 'when rebasing an MR from a fork where upstream has protected branches' do
    let(:upstream_project) { create(:project, :repository) }
    let(:fork_project) { create(:project, :repository) }

    let(:merge_request) do
      create(:merge_request,
             source_project: fork_project,
             source_branch: 'feature_conflict',
             target_project: upstream_project,
             target_branch: 'master')
    end

    before do
      create(:forked_project_link, forked_to_project: fork_project, forked_from_project: upstream_project)
    end

    it 'sets the correct project for running hooks' do
      expect(MergeRequests::RebaseService)
        .to receive(:new).with(fork_project, merge_request.author).and_call_original

      subject.perform(merge_request, merge_request.author)
    end
  end
end

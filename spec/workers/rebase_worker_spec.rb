# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RebaseWorker, '#perform' do
  include ProjectForksHelper

  context 'when rebasing an MR from a fork where upstream has protected branches' do
    let(:upstream_project) { create(:project, :repository) }
    let(:forked_project) { fork_project(upstream_project, nil, repository: true) }

    let(:merge_request) do
      create(:merge_request,
             source_project: forked_project,
             source_branch: 'feature_conflict',
             target_project: upstream_project,
             target_branch: 'master')
    end

    it 'sets the correct project for running hooks' do
      expect(MergeRequests::RebaseService)
        .to receive(:new).with(project: forked_project, current_user: merge_request.author).and_call_original

      subject.perform(merge_request.id, merge_request.author.id)
    end
  end
end

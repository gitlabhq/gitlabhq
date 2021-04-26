# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeWorker do
  describe "remove source branch" do
    let!(:merge_request) { create(:merge_request, source_branch: "markdown") }
    let!(:source_project) { merge_request.source_project }
    let!(:project) { merge_request.project }
    let!(:author) { merge_request.author }

    before do
      source_project.add_maintainer(author)
      source_project.repository.expire_branches_cache
    end

    it 'clears cache of source repo after removing source branch', :sidekiq_inline do
      expect(source_project.repository.branch_names).to include('markdown')

      described_class.new.perform(
        merge_request.id, merge_request.author_id,
        commit_message: 'wow such merge',
        sha: merge_request.diff_head_sha,
        should_remove_source_branch: true)

      merge_request.reload
      expect(merge_request).to be_merged

      source_project.repository.expire_branches_cache
      expect(source_project.repository.branch_names).not_to include('markdown')
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) do
        [
          merge_request.id,
          merge_request.author_id,
          commit_message: 'wow such merge',
          sha: merge_request.diff_head_sha
        ]
      end

      it 'the merge request is still shown as merged' do
        subject

        merge_request.reload
        expect(merge_request).to be_merged
      end
    end
  end
end

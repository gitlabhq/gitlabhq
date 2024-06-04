# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeWorker, feature_category: :code_review_workflow do
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
          { commit_message: 'wow such merge',
            sha: merge_request.diff_head_sha }
        ]
      end

      it 'the merge request is still shown as merged' do
        subject

        merge_request.reload
        expect(merge_request).to be_merged
      end
    end
  end

  describe 'delegation to MergeRequests::MergeService' do
    # Some ids that should be nonexistentn
    let(:user_id) { -1 }
    let(:merge_request_id) { -1 }
    let(:params) { {} }

    subject { described_class.new.perform(merge_request_id, user_id, params) }

    context 'when user exists' do
      let!(:user) { create(:user) }
      let(:user_id) { user.id }

      context 'and merge request exists' do
        let!(:merge_request) { create(:merge_request, source_project: create(:project, :empty_repo)) }
        let(:merge_request_id) { merge_request.id }
        let(:user) { merge_request.author }
        let(:merge_service_double) { instance_double(MergeRequests::MergeService) }

        it 'delegates to MergeRequests::MergeService' do
          expect(MergeRequests::MergeService).to receive(:new).with(
            project: merge_request.target_project,
            current_user: user,
            params: { check_mergeability_retry_lease: true }
          ).and_return(merge_service_double)

          expect(merge_service_double).to receive(:execute)
          subject
        end

        context 'and check_mergeability_retry_lease is specified' do
          let(:params) { { check_mergeability_retry_lease: false } }

          it 'does not change the check_mergeability_retry_lease parameter' do
            expect(MergeRequests::MergeService).to receive(:new).with(
              project: merge_request.target_project,
              current_user: user,
              params: params
            ).and_return(merge_service_double)

            expect(merge_service_double).to receive(:execute)
            subject
          end
        end
      end

      it 'does not call MergeRequests::MergeService' do
        expect(MergeRequests::MergeService).not_to receive(:new)
        subject
      end
    end

    it 'does not call MergeRequests::MergeService' do
      expect(MergeRequests::MergeService).not_to receive(:new)
      subject
    end
  end
end

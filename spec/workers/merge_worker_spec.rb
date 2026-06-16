# frozen_string_literal: true

require 'spec_helper'
require 'labkit/rspec/matchers'

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

  describe 'immediate_web_merge UX SLI' do
    let_it_be_with_reload(:merge_request) { create(:merge_request, source_branch: 'markdown') }
    let(:user) { merge_request.author }

    before do
      merge_request.source_project.add_maintainer(user)
    end

    context 'when the experience was started by the web merge' do
      before do
        Labkit::UserExperienceSli.start(:immediate_web_merge)
      end

      it 'resumes and completes the experience on a successful merge', :sidekiq_inline, :aggregate_failures do
        expect do
          described_class.new.perform(
            merge_request.id, user.id,
            { commit_message: 'wow such merge', sha: merge_request.diff_head_sha })
        end.to resume_user_experience(:immediate_web_merge)
          .and complete_user_experience(:immediate_web_merge)

        expect(merge_request.reload).to be_merged
      end

      it 'completes the experience with an error when the merge fails', :aggregate_failures do
        allow_next_instance_of(MergeRequests::MergeService) do |service|
          allow(service).to receive(:execute)
        end
        allow_next_found_instance_of(MergeRequest) do |found_mr|
          allow(found_mr).to receive_messages(merged?: false, merge_error: 'Merge conflict')
        end

        expect do
          described_class.new.perform(merge_request.id, user.id, {})
        end.to resume_user_experience(:immediate_web_merge)
          .and complete_user_experience(:immediate_web_merge, error: true)
      end

      it 'completes the experience with an error when the merge request is missing' do
        expect do
          described_class.new.perform(non_existing_record_id, user.id, {})
        end.to resume_user_experience(:immediate_web_merge)
          .and complete_user_experience(:immediate_web_merge, error: true)
      end
    end

    context 'when the experience was not started (GraphQL or auto-merge)' do
      it 'does not resume the experience' do
        expect do
          described_class.new.perform(non_existing_record_id, user.id, {})
        end.not_to resume_user_experience(:immediate_web_merge)
      end
    end
  end
end

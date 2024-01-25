# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateReviewersService, feature_category: :code_review_workflow do
  include AfterNextHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :private, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }

  let_it_be_with_reload(:merge_request) do
    create(
      :merge_request,
      :simple,
      :unique_branches,
      title: 'Old title',
      description: "FYI #{user2.to_reference}",
      reviewer_ids: [user3.id],
      source_project: project,
      target_project: project,
      author: create(:user)
    )
  end

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_developer(user3)
    merge_request.errors.clear
  end

  let(:service) { described_class.new(project: project, current_user: user, params: opts) }
  let(:opts) { { reviewer_ids: [user2.id] } }

  describe 'execute' do
    def set_reviewers
      service.execute(merge_request)
    end

    def find_note(starting_with)
      merge_request.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    shared_examples 'removing all reviewers' do
      it 'removes all reviewers' do
        expect(set_reviewers).to have_attributes(reviewers: be_empty, errors: be_none)
      end
    end

    context 'when the parameters are valid' do
      context 'when using sentinel values' do
        let(:opts) { { reviewer_ids: [0] } }

        it_behaves_like 'removing all reviewers'
      end

      context 'when the reviewer_ids parameter is the empty list' do
        let(:opts) { { reviewer_ids: [] } }

        it_behaves_like 'removing all reviewers'
      end

      it 'updates the MR' do
        expect { set_reviewers }
          .to change { merge_request.reload.reviewers }.from([user3]).to([user2])
          .and change(merge_request, :updated_at)
          .and change(merge_request, :updated_by).to(user)
      end

      it 'creates system note about merge_request review request' do
        set_reviewers

        note = find_note('requested review from')

        expect(note).not_to be_nil
        expect(note.note).to include "requested review from #{user2.to_reference}"
      end

      it 'creates a pending todo for new review request' do
        set_reviewers

        attributes = {
          project: project,
          author: user,
          user: user2,
          target_id: merge_request.id,
          target_type: merge_request.class.name,
          action: Todo::REVIEW_REQUESTED,
          state: :pending
        }

        expect(Todo.where(attributes).count).to eq 1
      end

      it 'sends email reviewer change notifications to old and new reviewers', :sidekiq_inline, :mailer do
        perform_enqueued_jobs do
          set_reviewers
        end

        should_email(user2)
        should_email(user3)
      end

      it 'updates open merge request counter for reviewers', :use_clean_rails_memory_store_caching do
        # Cache them to ensure the cache gets invalidated on update
        expect(user2.review_requested_open_merge_requests_count).to eq(0)
        expect(user3.review_requested_open_merge_requests_count).to eq(1)

        set_reviewers

        expect(user2.review_requested_open_merge_requests_count).to eq(1)
        expect(user3.review_requested_open_merge_requests_count).to eq(0)
      end

      it 'updates the tracking' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_users_review_requested)
          .with(users: [user2])

        set_reviewers
      end

      it 'tracks reviewers changed event' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_reviewers_changed_action).once.with(user: user)

        set_reviewers
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { set_reviewers }
      end

      it 'calls MergeRequest::ResolveTodosService#async_execute' do
        expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
          expect(service).to receive(:async_execute)
        end

        set_reviewers
      end

      it 'executes hooks with update action' do
        expect(service).to receive(:execute_hooks)
          .with(
            merge_request,
            'update',
            old_associations: {
              reviewers: [user3]
            }
          )

        set_reviewers
      end

      context 'when reviewers did not change' do
        let(:opts) { { reviewer_ids: merge_request.reviewer_ids } }

        it_behaves_like 'does not trigger GraphQL subscription mergeRequestReviewersUpdated' do
          let(:action) { set_reviewers }
        end
      end

      it 'does not update the reviewers if they do not have access' do
        opts[:reviewer_ids] = [create(:user).id]

        expect(set_reviewers).to have_attributes(
          reviewers: [user3],
          errors: be_any
        )
      end
    end

    context 'when user has no set_merge_request_metadata permissions' do
      before do
        allow(user).to receive(:can?).and_call_original

        allow(user)
          .to receive(:can?)
          .with(:set_merge_request_metadata, merge_request)
          .and_return(false)
      end

      it 'does not update the MR reviewers' do
        expect { set_reviewers }
          .not_to change { merge_request.reload.reviewers.to_a }
      end
    end
  end
end

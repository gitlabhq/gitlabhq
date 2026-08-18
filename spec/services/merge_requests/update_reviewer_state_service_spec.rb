# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateReviewerStateService, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:current_user) { create(:user) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, reviewers: [current_user]) }
  let(:reviewer) { merge_request.merge_request_reviewers.find_by(user_id: current_user.id) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: current_user) }
  let(:state) { 'requested_changes' }
  let(:result) { service.execute(merge_request, state) }

  before do
    project.add_developer(current_user)
  end

  describe '#execute' do
    shared_examples_for 'failed service execution' do
      it 'returns an error' do
        expect(result[:status]).to eq :error
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { result }
      end
    end

    describe 'invalid permissions' do
      let(:service) { described_class.new(project: project, current_user: create(:user)) }

      it_behaves_like 'failed service execution'
    end

    describe 'reviewer exists' do
      it 'returns success' do
        expect(result[:status]).to eq :success
      end

      context 'when updating reviewer state' do
        where(:initial_state, :new_state) do
          'unreviewed'        | 'requested_changes'
          'unreviewed'        | 'reviewed'
          'unreviewed'        | 'approved'
          'unreviewed'        | 'unapproved'
          'unreviewed'        | 'review_started'
          'requested_changes' | 'unreviewed'
        end

        with_them do
          it do
            reviewer.update!(state: initial_state)

            result = service.execute(merge_request, new_state)

            expect(result[:status]).to eq :success
            expect(reviewer.reload.state).to eq new_state
          end
        end
      end

      it 'calls SystemNoteService.requested_changes' do
        expect(SystemNoteService).to receive(:requested_changes)
          .with(merge_request, current_user)

        expect(result[:status]).to eq :success
      end

      it 'does not call MergeRequests::RemoveApprovalService' do
        expect(MergeRequests::RemoveApprovalService).not_to receive(:new)

        expect(result[:status]).to eq :success
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestReviewersUpdated' do
        let(:action) { result }
      end

      it 'triggers GraphQL subscription userMergeRequestUpdated' do
        expect(GraphqlTriggers).to receive(:user_merge_request_updated).with(current_user, merge_request)
        expect(GraphqlTriggers).to receive(:user_merge_request_updated).with(merge_request.author, merge_request)

        result
      end

      it 'invalidates cache counts for all assignees' do
        expect(merge_request.assignees).to all(receive(:invalidate_merge_request_cache_counts))

        expect(result[:status]).to eq :success
      end

      it 'invalidates cache counts for current user' do
        expect(current_user).to receive(:invalidate_merge_request_cache_counts)

        expect(result[:status]).to eq :success
      end

      context 'when reviewer has approved' do
        before do
          create(:approval, user: current_user, merge_request: merge_request)
        end

        describe 'updating state of reviewer' do
          where(:initial_state, :new_state, :status) do
            'approved'       | 'reviewed'          | :error
            'approved'       | 'review_started'    | :error
            'approved'       | 'requested_changes' | :success
            'approved'       | 'unapproved'        | :success
          end

          with_them do
            it do
              reviewer.update!(state: initial_state)

              result = service.execute(merge_request, new_state)

              expect(result[:status]).to eq status
            end
          end
        end

        it 'removes approval when state is requested_changes' do
          expect_next_instance_of(
            MergeRequests::RemoveApprovalService,
            project: project, current_user: current_user
          ) do |service|
            expect(service).to receive(:execute)
              .with(merge_request, skip_system_note: true, skip_notification: true, skip_updating_state: true)
              .and_return({ success: true })
          end

          expect(result[:status]).to eq :success
        end

        it 'renders error when remove approval service fails' do
          expect_next_instance_of(
            MergeRequests::RemoveApprovalService,
            project: project, current_user: current_user
          ) do |service|
            expect(service).to receive(:execute)
              .with(merge_request, skip_system_note: true, skip_notification: true, skip_updating_state: true)
              .and_return(nil)
          end

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq "Failed to remove approval"
        end
      end

      context 'when reviewer state is "reviewed"' do
        let(:state) { 'reviewed' }

        it 'calls SystemNoteService.reviewed' do
          expect(SystemNoteService).to receive(:reviewed)
            .with(merge_request, current_user)

          expect(result[:status]).to eq :success
        end
      end

      describe 'webhooks' do
        before do
          reviewer.update!(state: 'unreviewed')
        end

        it 'executes hooks with the old reviewer hook attributes' do
          expect(service).to receive(:execute_hooks).with(
            merge_request,
            'update',
            hash_including(old_associations: hash_including(:reviewers_hook_attrs))
          ).and_call_original

          expect(result[:status]).to eq :success
        end

        it 'captures the old reviewer state before the update' do
          old_associations_data = nil

          allow(service).to receive(:execute_hooks) do |_mr, _action, options|
            old_associations_data = options[:old_associations]
          end

          expect(result[:status]).to eq :success

          old_reviewer_data = old_associations_data[:reviewers_hook_attrs].find { |r| r[:id] == current_user.id }
          expect(old_reviewer_data[:state]).to eq('unreviewed')
        end

        it 'includes the new reviewer state in the webhook payload changes' do
          changes = nil

          allow(service).to receive(:execute_hooks) do |mr, _action, options|
            changes = mr.hook_reviewer_changes(options[:old_associations])
          end

          expect(result[:status]).to eq :success

          expect(changes).to have_key(:reviewers)

          old_reviewer = changes[:reviewers].first.find { |r| r[:id] == current_user.id }
          current_reviewer = changes[:reviewers].last.find { |r| r[:id] == current_user.id }

          expect(old_reviewer[:state]).to eq('unreviewed')
          expect(current_reviewer[:state]).to eq('requested_changes')
        end

        context 'when reviewer state is "reviewed"' do
          let(:state) { 'reviewed' }

          it 'executes hooks reflecting the reviewed state' do
            changes = nil

            allow(service).to receive(:execute_hooks) do |mr, _action, options|
              changes = mr.hook_reviewer_changes(options[:old_associations])
            end

            expect(result[:status]).to eq :success

            current_reviewer = changes[:reviewers].last.find { |r| r[:id] == current_user.id }
            expect(current_reviewer[:state]).to eq('reviewed')
          end
        end

        context 'when the reviewer state does not change' do
          before do
            reviewer.update!(state: 'requested_changes')
          end

          it 'does not include a reviewer change in the webhook payload' do
            changes = nil

            allow(service).to receive(:execute_hooks) do |mr, _action, options|
              changes = mr.hook_reviewer_changes(options[:old_associations])
            end

            expect(result[:status]).to eq :success

            expect(changes).not_to have_key(:reviewers)
          end
        end

        # Approving and unapproving are review submissions too, so they fire this webhook
        # even though they also emit their own dedicated approved/unapproved webhooks.
        context 'when submitting an approval or unapproval' do
          where(:submitted_state) do
            %w[approved unapproved].map { |reviewer_state| [reviewer_state] }
          end

          with_them do
            it 'executes the reviewer-state webhook' do
              expect(service).to receive(:execute_hooks).with(
                merge_request,
                'update',
                hash_including(old_associations: hash_including(:reviewers_hook_attrs))
              ).and_call_original

              expect(service.execute(merge_request, submitted_state)[:status]).to eq :success
            end
          end
        end

        # review_started (set when a draft note is created) and unreviewed (set when the last
        # draft note is destroyed or reviewers are reset on push) are automatic transitions,
        # not a review the user submitted, so they must not fire this webhook.
        context 'when the state is an automatic transition' do
          where(:automatic_state) do
            %w[review_started unreviewed].map { |reviewer_state| [reviewer_state] }
          end

          with_them do
            it 'does not execute the reviewer-state webhook' do
              expect(service).not_to receive(:execute_hooks)

              expect(service.execute(merge_request, automatic_state)[:status]).to eq :success
            end
          end
        end
      end
    end
  end
end

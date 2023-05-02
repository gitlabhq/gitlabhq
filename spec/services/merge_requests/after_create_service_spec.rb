# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AfterCreateService, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  subject(:after_create_service) do
    described_class.new(project: merge_request.target_project, current_user: merge_request.author)
  end

  describe '#execute' do
    let(:event_service) { instance_double('EventCreateService', open_mr: true) }
    let(:notification_service) { instance_double('NotificationService', new_merge_request: true) }

    before do
      allow(after_create_service).to receive(:event_service).and_return(event_service)
      allow(after_create_service).to receive(:notification_service).and_return(notification_service)
    end

    subject(:execute_service) { after_create_service.execute(merge_request) }

    it 'creates a merge request open event' do
      expect(event_service)
        .to receive(:open_mr).with(merge_request, merge_request.author)

      execute_service
    end

    it 'calls the merge request activity counter' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_create_mr_action)
        .with(user: merge_request.author, merge_request: merge_request)

      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_mr_including_ci_config)
        .with(user: merge_request.author, merge_request: merge_request)

      execute_service
    end

    it 'creates a new merge request notification' do
      expect(notification_service)
        .to receive(:new_merge_request).with(merge_request, merge_request.author)

      execute_service
    end

    it 'writes diffs to the cache' do
      expect(merge_request)
        .to receive_message_chain(:diffs, :write_cache)

      execute_service
    end

    it 'creates cross references' do
      expect(merge_request)
        .to receive(:create_cross_references!).with(merge_request.author)

      execute_service
    end

    it 'creates a pipeline and updates the HEAD pipeline' do
      expect(after_create_service)
        .to receive(:create_pipeline_for).with(merge_request, merge_request.author)
      expect(merge_request).to receive(:update_head_pipeline)

      execute_service
    end

    it 'executes hooks with default action' do
      expect(project).to receive(:execute_hooks)

      execute_service
    end

    it_behaves_like 'records an onboarding progress action', :merge_request_created do
      let(:namespace) { merge_request.target_project.namespace }
    end

    context 'when merge request is in unchecked state' do
      before do
        merge_request.mark_as_unchecked!
        execute_service
      end

      it 'does not change its state' do
        expect(merge_request.reload).to be_unchecked
      end
    end

    context 'when merge request is in preparing state' do
      before do
        merge_request.mark_as_unchecked! unless merge_request.unchecked?
        merge_request.mark_as_preparing!
      end

      it 'checks for mergeability' do
        expect(merge_request).to receive(:check_mergeability).with(async: true)

        execute_service
      end

      context 'when preparing for mergeability fails' do
        before do
          # This is only one of the possible cases that can fail. This is to
          # simulate a failure that happens during the service call.
          allow(merge_request)
            .to receive(:update_head_pipeline)
            .and_raise(StandardError)
        end

        it 'does not mark the merge request as unchecked' do
          expect { execute_service }.to raise_error(StandardError)
          expect(merge_request.reload).to be_preparing
        end
      end

      context 'when preparing merge request fails' do
        before do
          # This is only one of the possible cases that can fail. This is to
          # simulate a failure that happens during the service call.
          allow(merge_request)
            .to receive_message_chain(:diffs, :write_cache)
            .and_raise(StandardError)
        end

        it 'still checks for mergeability' do
          expect(merge_request).to receive(:check_mergeability).with(async: true)
          expect { execute_service }.to raise_error(StandardError)
        end
      end
    end

    it 'updates the prepared_at' do
      # Need to reset the `prepared_at` since it can be already set in preceding tests.
      merge_request.update!(prepared_at: nil)

      freeze_time do
        expect { execute_service }.to change { merge_request.prepared_at }
          .from(nil)
          .to(Time.current)
      end
    end

    it 'increments the usage data counter of create event' do
      counter = Gitlab::UsageDataCounters::MergeRequestCounter

      expect { execute_service }.to change { counter.read(:create) }.by(1)
    end

    context 'todos' do
      it 'does not creates todos' do
        attributes = {
          project: merge_request.target_project,
          target_id: merge_request.id,
          target_type: merge_request.class.name
        }

        expect { execute_service }.not_to change { Todo.where(attributes).count }
      end

      context 'when merge request is assigned to someone' do
        let_it_be(:assignee) { create(:user) }
        let_it_be(:merge_request) { create(:merge_request, assignees: [assignee]) }

        it 'creates a todo for new assignee' do
          attributes = {
            project: merge_request.target_project,
            author: merge_request.author,
            user: assignee,
            target_id: merge_request.id,
            target_type: merge_request.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect { execute_service }.to change { Todo.where(attributes).count }.by(1)
        end
      end

      context 'when reviewer is assigned' do
        let_it_be(:reviewer) { create(:user) }
        let_it_be(:merge_request) { create(:merge_request, reviewers: [reviewer]) }

        it 'creates a todo for new reviewer' do
          attributes = {
            project: merge_request.target_project,
            author: merge_request.author,
            user: reviewer,
            target_id: merge_request.id,
            target_type: merge_request.class.name,
            action: Todo::REVIEW_REQUESTED,
            state: :pending
          }

          expect { execute_service }.to change { Todo.where(attributes).count }.by(1)
        end
      end
    end

    context 'when saving references to issues that the created merge request closes' do
      let_it_be(:first_issue) { create(:issue, project: merge_request.target_project) }
      let_it_be(:second_issue) { create(:issue, project: merge_request.target_project) }

      it 'creates a `MergeRequestsClosingIssues` record for each issue' do
        merge_request.description = "Closes #{first_issue.to_reference} and #{second_issue.to_reference}"
        merge_request.source_branch = "feature"
        merge_request.target_branch = merge_request.target_project.default_branch
        merge_request.save!

        execute_service

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to match_array([first_issue.id, second_issue.id])
      end
    end

    it 'tracks merge request creation in usage data' do
      expect(Gitlab::UsageDataCounters::MergeRequestCounter).to receive(:count).with(:create)

      execute_service
    end

    it 'calls MergeRequests::LinkLfsObjectsService#execute' do
      service = instance_spy(MergeRequests::LinkLfsObjectsService)
      allow(MergeRequests::LinkLfsObjectsService).to receive(:new).with(project: merge_request.target_project).and_return(service)

      execute_service

      expect(service).to have_received(:execute).with(merge_request)
    end
  end
end

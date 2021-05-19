# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AfterCreateService do
  let_it_be(:merge_request) { create(:merge_request) }

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
        .with(user: merge_request.author)

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
        merge_request.mark_as_preparing!
        execute_service
      end

      it 'marks the merge request as unchecked' do
        expect(merge_request.reload).to be_unchecked
      end
    end

    it 'increments the usage data counter of create event' do
      counter = Gitlab::UsageDataCounters::MergeRequestCounter

      expect { execute_service }.to change { counter.read(:create) }.by(1)
    end

    context 'with a milestone' do
      let(:milestone) { create(:milestone, project: merge_request.target_project) }

      before do
        merge_request.update!(milestone_id: milestone.id)
      end

      it 'deletes the cache key for milestone merge request counter', :use_clean_rails_memory_store_caching do
        expect_next_instance_of(Milestones::MergeRequestsCountService, milestone) do |service|
          expect(service).to receive(:delete_cache).and_call_original
        end

        execute_service
      end
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

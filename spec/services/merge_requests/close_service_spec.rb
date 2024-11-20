# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CloseService, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:guest) { create(:user) }
  let(:merge_request) { create(:merge_request, assignees: [user2], author: create(:user)) }
  let(:project) { merge_request.project }
  let!(:todo) { create(:todo, :assigned, user: user, project: project, target: merge_request, author: user2) }
  let(:service) { described_class.new(project: project, current_user: user) }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_guest(guest)
  end

  def execute
    service.execute(merge_request)
  end

  describe '#execute' do
    it_behaves_like 'cache counters invalidator'
    it_behaves_like 'merge request reviewers cache counters invalidator'

    context 'valid params' do
      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          @merge_request = execute
        end
      end

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request).to be_closed }

      it 'executes hooks with close action' do
        expect(service).to have_received(:execute_hooks)
                             .with(@merge_request, 'close')
      end

      it 'sends email to user2 about assign of new merge_request', :sidekiq_inline do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'creates a resource event' do
        event = @merge_request.resource_state_events.last
        expect(event.state).to eq('closed')
      end

      it 'marks todos as done' do
        expect(todo.reload).to be_done
      end

      context 'when auto merge is enabled' do
        let(:merge_request) { create(:merge_request, :merge_when_checks_pass) }

        it 'cancels the auto merge' do
          expect(@merge_request).not_to be_auto_merge_enabled
        end
      end
    end

    it 'updates metrics' do
      metrics = merge_request.metrics
      metrics_service = double(MergeRequestMetricsService)
      allow(MergeRequestMetricsService)
        .to receive(:new)
        .with(metrics)
        .and_return(metrics_service)

      expect(metrics_service).to receive(:close)

      execute
    end

    it 'calls the merge request activity counter' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_close_mr_action)
        .with(user: user)

      execute
    end

    it 'refreshes the number of open merge requests for a valid MR', :use_clean_rails_memory_store_caching do
      expect do
        execute

        BatchLoader::Executor.clear_current
      end
        .to change { project.open_merge_requests_count }.from(1).to(0)
    end

    it 'clean up environments for the merge request' do
      expect_next_instance_of(::Environments::StopService) do |service|
        expect(service).to receive(:execute_for_merge_request_pipeline).with(merge_request)
      end

      execute
    end

    it 'triggers deletion of related Pages deployments' do
      expect(Pages::DeactivateMrDeploymentsWorker)
        .to receive(:perform_async)
          .with(merge_request.id)

      execute
    end

    it 'schedules CleanupRefsService' do
      expect(MergeRequests::CleanupRefsService).to receive(:schedule).with(merge_request)

      execute
    end

    it 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
      expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(merge_request)

      execute
    end

    context 'current user is not authorized to close merge request' do
      let(:user) { guest }

      before do
        perform_enqueued_jobs do
          @merge_request = execute
        end
      end

      it 'does not close the merge request' do
        expect(@merge_request).to be_open
      end

      it 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
        expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated)

        execute
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::CloseService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:guest) { create(:user) }
  let(:merge_request) { create(:merge_request, assignees: [user2], author: create(:user)) }
  let(:project) { merge_request.project }
  let!(:todo) { create(:todo, :assigned, user: user, project: project, target: merge_request, author: user2) }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_guest(guest)
  end

  describe '#execute' do
    it_behaves_like 'cache counters invalidator'

    [true, false].each do |state_tracking_enabled|
      context "valid params with state_tracking #{state_tracking_enabled ? 'enabled' : 'disabled'}" do
        let(:service) { described_class.new(project, user, {}) }

        before do
          stub_feature_flags(track_resource_state_change_events: state_tracking_enabled)

          allow(service).to receive(:execute_hooks)

          perform_enqueued_jobs do
            @merge_request = service.execute(merge_request)
          end
        end

        it { expect(@merge_request).to be_valid }
        it { expect(@merge_request).to be_closed }

        it 'executes hooks with close action' do
          expect(service).to have_received(:execute_hooks)
                               .with(@merge_request, 'close')
        end

        it 'sends email to user2 about assign of new merge_request', :sidekiq_might_not_need_inline do
          email = ActionMailer::Base.deliveries.last
          expect(email.to.first).to eq(user2.email)
          expect(email.subject).to include(merge_request.title)
        end

        it 'creates system note about merge_request reassign' do
          if state_tracking_enabled
            event = @merge_request.resource_state_events.last
            expect(event.state).to eq('closed')
          else
            note = @merge_request.notes.last
            expect(note.note).to include 'closed'
          end
        end

        it 'marks todos as done' do
          expect(todo.reload).to be_done
        end

        context 'when auto merge is enabled' do
          let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

          it 'cancels the auto merge' do
            expect(@merge_request).not_to be_auto_merge_enabled
          end
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

      described_class.new(project, user, {}).execute(merge_request)
    end

    it 'refreshes the number of open merge requests for a valid MR', :use_clean_rails_memory_store_caching do
      service = described_class.new(project, user, {})

      expect { service.execute(merge_request) }
        .to change { project.open_merge_requests_count }.from(1).to(0)
    end

    it 'clean up environments for the merge request' do
      expect_next_instance_of(Ci::StopEnvironmentsService) do |service|
        expect(service).to receive(:execute_for_merge_request).with(merge_request)
      end

      described_class.new(project, user).execute(merge_request)
    end

    context 'current user is not authorized to close merge request' do
      before do
        perform_enqueued_jobs do
          @merge_request = described_class.new(project, guest).execute(merge_request)
        end
      end

      it 'does not close the merge request' do
        expect(@merge_request).to be_open
      end
    end
  end
end

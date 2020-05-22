# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::ReopenService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:guest) { create(:user) }
  let(:merge_request) { create(:merge_request, :closed, assignees: [user2], author: create(:user)) }
  let(:project) { merge_request.project }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_guest(guest)
  end

  describe '#execute' do
    it_behaves_like 'cache counters invalidator'

    context 'valid params' do
      let(:service) { described_class.new(project, user, {}) }
      let(:state_tracking) { true }

      before do
        stub_feature_flags(track_resource_state_change_events: state_tracking)

        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      it { expect(merge_request).to be_valid }
      it { expect(merge_request).to be_opened }

      it 'executes hooks with reopen action' do
        expect(service).to have_received(:execute_hooks)
                               .with(merge_request, 'reopen')
      end

      it 'sends email to user2 about reopen of merge_request', :sidekiq_might_not_need_inline do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(merge_request.title)
      end

      context 'note creation' do
        context 'when state event tracking is disabled' do
          let(:state_tracking) { false }

          it 'creates system note about merge_request reopen' do
            note = merge_request.notes.last
            expect(note.note).to include 'reopened'
          end
        end

        context 'when state event tracking is enabled' do
          it 'creates resource state event about merge_request reopen' do
            event = merge_request.resource_state_events.last
            expect(event.state).to eq('reopened')
          end
        end
      end
    end

    it 'caches merge request closing issues' do
      expect(merge_request).to receive(:cache_merge_request_closes_issues!)

      described_class.new(project, user, {}).execute(merge_request)
    end

    it 'updates metrics' do
      metrics = merge_request.metrics
      service = double(MergeRequestMetricsService)
      allow(MergeRequestMetricsService)
        .to receive(:new)
        .with(metrics)
        .and_return(service)

      expect(service).to receive(:reopen)

      described_class.new(project, user, {}).execute(merge_request)
    end

    it 'refreshes the number of open merge requests for a valid MR' do
      service = described_class.new(project, user, {})

      expect { service.execute(merge_request) }
        .to change { project.open_merge_requests_count }.from(0).to(1)
    end

    context 'current user is not authorized to reopen merge request' do
      before do
        perform_enqueued_jobs do
          @merge_request = described_class.new(project, guest).execute(merge_request)
        end
      end

      it 'does not reopen the merge request' do
        expect(@merge_request).to be_closed
      end
    end
  end
end

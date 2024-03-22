# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ReopenService, feature_category: :team_planning do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, :closed, :unchanged, project: project) }

  describe '#execute' do
    context 'when user is not authorized to reopen issue' do
      it 'does not reopen the issue' do
        guest = create(:user)
        project.add_guest(guest)

        described_class.new(container: project, current_user: guest).execute(issue)

        expect(issue).to be_closed
      end

      context 'when skip_authorization is true' do
        it 'does close the issue even if user is not authorized' do
          non_authorized_user = create(:user)

          service = described_class.new(container: project, current_user: non_authorized_user)

          expect do
            service.execute(issue, skip_authorization: true)
          end.to change { issue.reload.state }.from('closed').to('opened')
        end
      end
    end

    context 'when user is authorized to reopen issue' do
      let(:user) { create(:user) }

      subject(:execute) { described_class.new(container: project, current_user: user).execute(issue) }

      before do
        project.add_maintainer(user)
      end

      it 'invalidates counter cache for assignees' do
        issue.assignees << user
        expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts)

        execute
      end

      it 'refreshes the number of opened issues' do
        expect do
          execute

          BatchLoader::Executor.clear_current
        end.to change { project.open_issues_count }.from(0).to(1)
      end

      it 'deletes milestone issue counters cache' do
        issue.update!(milestone: create(:milestone, project: project))

        expect_next_instance_of(Milestones::ClosedIssuesCountService, issue.milestone) do |service|
          expect(service).to receive(:delete_cache).and_call_original
        end

        execute
      end

      it 'does not create timeline event' do
        expect { execute }.not_to change { issue.incident_management_timeline_events.count }
      end

      it 'does not call GroupMentionWorker' do
        expect(Integrations::GroupMentionWorker).not_to receive(:perform_async)

        issue
      end

      context 'issue is incident type' do
        let(:issue) { create(:incident, :closed, project: project) }
        let(:current_user) { user }

        it_behaves_like 'an incident management tracked event', :incident_management_incident_reopened

        it_behaves_like 'Snowplow event tracking with RedisHLL context' do
          let(:namespace) { issue.namespace }
          let(:category) { described_class.to_s }
          let(:action) { 'incident_management_incident_reopened' }
          let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
        end

        it 'creates a timeline event' do
          expect(IncidentManagement::TimelineEvents::CreateService)
            .to receive(:reopen_incident)
            .with(issue, current_user)
            .and_call_original

          expect { execute }.to change { issue.incident_management_timeline_events.count }.by(1)
        end
      end

      context 'when issue is not confidential' do
        let(:expected_payload) do
          include(
            event_type: 'issue',
            object_kind: 'issue',
            changes: {
              closed_at: { current: nil, previous: kind_of(Time) },
              state_id: { current: 1, previous: 2 },
              updated_at: { current: kind_of(Time), previous: kind_of(Time) }
            },
            object_attributes: include(
              state: 'opened',
              action: 'reopen'
            )
          )
        end

        it 'executes issue hooks' do
          expect(project.project_namespace).to receive(:execute_hooks).with(expected_payload, :issue_hooks)
          expect(project.project_namespace).to receive(:execute_integrations).with(expected_payload, :issue_hooks)

          execute
        end
      end

      context 'when issue is confidential' do
        let(:issue) { create(:issue, :confidential, :closed, project: project) }

        it 'executes confidential issue hooks' do
          issue_hooks = :confidential_issue_hooks
          expect(project.project_namespace).to receive(:execute_hooks).with(an_instance_of(Hash), issue_hooks)
          expect(project.project_namespace).to receive(:execute_integrations).with(an_instance_of(Hash), issue_hooks)

          execute
        end
      end
    end
  end
end

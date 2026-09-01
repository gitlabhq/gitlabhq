# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CloseService, feature_category: :team_planning do
  let_it_be(:parent_namespace) { create(:namespace) }
  let(:project) do
    create(:project, :repository, namespace: parent_namespace, maintainers: user, developers: user2, guests: guest)
  end

  let(:delegated_project) { project.project_namespace.project }
  let_it_be(:user) { create(:user, email: "user@example.com") }
  let(:user2) { create(:user, email: "user2@example.com") }
  let_it_be(:guest) { create(:user) }
  let_it_be(:author) { create(:user) }
  let(:issue) { create(:issue, :unchanged, title: "My issue", project: project, assignees: [user2], author: author) }
  let(:external_issue) { ExternalIssue.new('JIRA-123', project) }
  let(:closing_merge_request) { create(:merge_request, :unchanged, source_project: project) }
  let(:closing_commit) { create(:commit, project: project) }
  let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

  describe '#execute' do
    let(:service) { described_class.new(container: project, current_user: user) }

    context 'when skip_authorization is true' do
      it 'does close the issue even if user is not authorized' do
        non_authorized_user = create(:user)

        service = described_class.new(container: project, current_user: non_authorized_user)

        expect do
          service.execute(issue, skip_authorization: true)
        end.to change { issue.reload.state }.from('opened').to('closed')
      end
    end

    context 'when the user is not authorized to close the issue' do
      let(:target_issue) { issue }

      before do
        allow(service).to receive(:can?).with(user, :update_issue, target_issue).and_return(false)
      end

      it 'does not close the issue and logs the failed authorization', :aggregate_failures do
        expect(service).not_to receive(:close_issue)
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            class: 'Issues::CloseService',
            current_user_id: user.id,
            issue_id: target_issue.id,
            message: 'Unauthorized close issue'
          }.stringify_keys
        )

        expect(service.execute(issue)).to eq(issue)
      end

      context 'when issue is closed via merge request' do
        it 'logs the failed authorization' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            {
              class: 'Issues::CloseService',
              current_user_id: user.id,
              issue_id: target_issue.id,
              message: 'Unauthorized close issue',
              merge_request_id: closing_merge_request.id
            }.stringify_keys
          )

          service.execute(issue, commit: closing_merge_request)
        end
      end

      context 'when issue is closed via commit' do
        it 'logs the failed authorization' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            {
              class: 'Issues::CloseService',
              current_user_id: user.id,
              issue_id: target_issue.id,
              message: 'Unauthorized close issue',
              commit: closing_commit.id
            }.stringify_keys
          )

          service.execute(issue, commit: closing_commit)
        end
      end

      context 'when issue is external' do
        let(:target_issue) { external_issue }

        it 'closes the external issue even when the user is not authorized to do so' do
          expect(service).to receive(:close_issue)
            .with(external_issue, closed_via: nil, notifications: true, system_note: true, status: nil)

          service.execute(external_issue)
        end
      end
    end

    it 'closes the issue when the user is authorized to do so' do
      allow(service).to receive(:can?).with(user, :update_issue, issue)
        .and_return(true)

      expect(service).to receive(:close_issue)
        .with(issue, closed_via: nil, notifications: true, system_note: true, status: nil)

      service.execute(issue)
    end

    it 'checks authorization, refreshes the number of open issues, invalidates assignee counter cache, ' \
      'does not change escalation status, and broadcasts namespaceWorkItemChanges',
      :use_clean_rails_memory_store_caching, :aggregate_failures do
      resolved = IncidentManagement::Escalatable::STATUSES[:resolved]

      expect(service).to receive(:can?).with(user, :update_issue, issue).and_call_original
      expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts)
      allow(GitlabSchema.subscriptions).to receive(:trigger)
      allow(Gitlab::ApplicationRateLimiter).to receive(:peek)
        .with(:namespace_work_item_changes_broadcast, scope: anything).and_return(false)
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:namespace_work_item_changes_broadcast, scope: anything).and_return(false)

      expect do
        service.execute(issue)

        BatchLoader::Executor.clear_current
      end.to change { project.open_issues_count }.from(1).to(0)
        .and not_change { IncidentManagement::IssuableEscalationStatus.where(issue: issue).count }
        .and not_change { IncidentManagement::IssuableEscalationStatus.where(status: resolved).count }

      expect(GitlabSchema.subscriptions).to have_received(:trigger).with(
        'namespaceWorkItemChanges',
        { namespace_id: project.project_namespace.to_gid },
        { work_item_id: issue.id, action: :updated }
      )
    end

    it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
      subject(:execute_service) { service.execute(issue) }
    end

    context 'issue is incident type' do
      let(:issue) { create(:incident, project: project) }
      let(:current_user) { user }

      subject { service.execute(issue) }

      it_behaves_like 'an incident management tracked event', :incident_management_incident_closed

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { issue.namespace }
        let(:category) { described_class.to_s }
        let(:action) { 'incident_management_incident_closed' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end

      it 'creates a new escalation resolved escalation status', :aggregate_failures do
        expect { service.execute(issue) }.to change { IncidentManagement::IssuableEscalationStatus.where(issue: issue).count }.by(1)

        expect(issue.incident_management_issuable_escalation_status).to be_resolved
      end

      context 'when there is an escalation status' do
        before do
          create(:incident_management_issuable_escalation_status, issue: issue)
        end

        it 'resolves the escalation status, adds a system note, and adds a timeline event', :aggregate_failures do
          expect(IncidentManagement::TimelineEvents::CreateService)
            .to receive(:resolve_incident)
            .with(issue, user)
            .and_call_original

          expect { service.execute(issue) }
            .to change { issue.incident_management_issuable_escalation_status.reload.resolved? }.to(true)
            .and change { issue.notes.count }.by(1)
            .and change { issue.incident_management_timeline_events.count }.by(1)

          new_note = issue.notes.last
          expect(new_note.note).to eq('changed the incident status to **Resolved** by closing the incident')
          expect(new_note.author).to eq(user)
        end

        context 'when the escalation status did not change to resolved' do
          let(:escalation_status) { instance_double('IncidentManagement::IssuableEscalationStatus', resolve: false, status_name: 'acknowledged') }

          before do
            allow(issue).to receive(:incident_management_issuable_escalation_status).and_return(escalation_status)
          end

          it 'does not create a system note or a timeline event', :aggregate_failures do
            expect { service.execute(issue) }
              .to not_change { issue.notes.count }
              .and not_change { issue.incident_management_timeline_events.count }
          end
        end
      end
    end
  end

  describe '#close_issue' do
    context 'with external issue' do
      context 'with an active external issue tracker supporting close_issue' do
        let!(:external_issue_tracker) { create(:jira_integration, project: project) }

        it 'closes the issue on the external issue tracker' do
          project.reload
          expect(project.external_issue_tracker).to receive(:close_issue)

          described_class.new(container: project, current_user: user).close_issue(external_issue)
        end
      end

      context 'with inactive external issue tracker supporting close_issue' do
        let!(:external_issue_tracker) { create(:jira_integration, project: project, active: false) }

        it 'does not close the issue on the external issue tracker' do
          project.reload
          expect(project.external_issue_tracker).not_to receive(:close_issue)

          described_class.new(container: project, current_user: user).close_issue(external_issue)
        end
      end

      context 'with an active external issue tracker not supporting close_issue' do
        let!(:external_issue_tracker) { create(:bugzilla_integration, project: project) }

        it 'does not close the issue on the external issue tracker' do
          project.reload
          expect(project.external_issue_tracker).not_to receive(:close_issue)

          described_class.new(container: project, current_user: user).close_issue(external_issue)
        end
      end
    end

    context "closed by a merge request" do
      subject(:close_issue) do
        perform_enqueued_jobs do
          described_class.new(container: project, current_user: user).close_issue(issue, closed_via: closing_merge_request)
        end
      end

      it 'mentions closure via a merge request' do
        expect_next_instance_of(NotificationService::Async) do |service|
          expect(service).to receive(:close_issue).with(issue, user, { closed_via: closing_merge_request })
        end

        close_issue
      end

      context 'updating `metrics.first_mentioned_in_commit_at`' do
        context 'when `metrics.first_mentioned_in_commit_at` is not set' do
          it 'uses the first commit authored timestamp' do
            expected = closing_merge_request.commits.take(100).last.authored_date

            close_issue

            expect(issue.metrics.first_mentioned_in_commit_at).to eq(expected)
          end
        end

        context 'when `metrics.first_mentioned_in_commit_at` is already set' do
          before do
            issue.metrics.update!(first_mentioned_in_commit_at: Time.current)
          end

          it 'does not update the metrics' do
            expect { close_issue }.not_to change { issue.metrics.first_mentioned_in_commit_at }
          end
        end

        context 'when merge request has no commits' do
          let(:closing_merge_request) { create(:merge_request, :without_diffs, source_project: project) }

          it 'does not update the metrics' do
            close_issue

            expect(issue.metrics.first_mentioned_in_commit_at).to be_nil
          end
        end
      end
    end

    context "closed by a commit", :sidekiq_might_not_need_inline do
      it 'mentions closure via a commit' do
        expect_next_instance_of(NotificationService::Async) do |service|
          expect(service).to receive(:close_issue).with(issue, user, { closed_via: "commit #{closing_commit.id}" })
        end

        described_class.new(container: project, current_user: user).close_issue(issue, closed_via: closing_commit)
      end
    end

    context "valid params" do
      subject(:close_issue) do
        perform_enqueued_jobs do
          described_class.new(container: project, current_user: user).close_issue(issue)
        end
      end

      it 'verifies the number of queries', :request_store do
        recorded = ActiveRecord::QueryRecorder.new { close_issue }
        expected_queries = 42

        expect(recorded.count).to be <= expected_queries
        expect(recorded.cached_count).to eq(0)
      end

      it 'closes the issue, records closed user, creates a resource state event, and marks todos as done',
        :aggregate_failures do
        close_issue

        expect(issue).to be_valid
        expect(issue).to be_closed
        expect(issue.reload.closed_by_id).to be(user.id)

        event = issue.resource_state_events.last
        expect(event.state).to eq('closed')

        expect(todo.reload).to be_done
      end

      it 'sends notification', :sidekiq_might_not_need_inline do
        expect_next_instance_of(NotificationService::Async) do |service|
          expect(service).to receive(:close_issue).with(issue, user, { closed_via: nil })
        end

        close_issue
      end

      context 'when closing the issue fails' do
        it 'does not assign a closed_by value for the issue' do
          allow(issue).to receive(:close).and_return(false)

          close_issue

          expect(issue.closed_by_id).to be_nil
        end
      end

      context 'when there is an associated Alert Management Alert' do
        context 'when alert can be resolved' do
          it 'resolves an alert and sends a system note' do
            alert = create(:alert_management_alert, issue: issue, project: project)

            expect(SystemNoteService).to receive(:change_alert_status)
              .with(alert, Users::Internal.in_organization(project.organization).alert_bot, " because #{user.to_reference} closed incident #{issue.to_reference(project)}")

            close_issue

            expect(alert.reload).to be_resolved
          end
        end

        context 'when alert cannot be resolved' do
          before do
            allow(Gitlab::AppLogger).to receive(:warn).and_call_original
          end

          it 'writes a warning into the log' do
            alert = create(:alert_management_alert, :with_validation_errors, issue: issue, project: project)

            close_issue

            expect(Gitlab::AppLogger).to have_received(:warn).with(
              message: 'Cannot resolve an associated Alert Management alert',
              issue_id: issue.id,
              alert_id: alert.id,
              alert_errors: { hosts: ['hosts array is over 255 chars'] }
            )
          end
        end
      end

      context 'when there are several associated Alert Management Alerts' do
        context 'when alerts can be resolved' do
          it 'resolves an alert and sends a system note', :aggregate_failures do
            alerts = create_list(:alert_management_alert, 2, issue: issue, project: project)

            alerts.each do |alert|
              expect(SystemNoteService).to receive(:change_alert_status)
                .with(alert, Users::Internal.in_organization(project.organization).alert_bot, " because #{user.to_reference} closed incident #{issue.to_reference(project)}")
            end

            close_issue

            expect(alerts.map(&:reload)).to all(be_resolved)
          end
        end
      end

      it 'deletes milestone issue counters cache' do
        issue.update!(milestone: create(:milestone, project: project))

        expect_next_instance_of(Milestones::ClosedIssuesCountService, issue.milestone) do |service|
          expect(service).to receive(:delete_cache).and_call_original
        end

        close_issue
      end

      it_behaves_like 'tracks work item event', :issue, :user, ::Gitlab::WorkItems::Instrumentation::EventActions::CLOSE, :close_issue
    end

    context 'when issue is not confidential' do
      let(:expected_payload) do
        include(
          event_type: 'issue',
          object_kind: 'issue',
          changes: {
            closed_at: { current: kind_of(Time), previous: nil },
            state_id: { current: 2, previous: 1 },
            updated_at: { current: kind_of(Time), previous: kind_of(Time) }
          },
          object_attributes: include(
            closed_at: kind_of(Time),
            state: 'closed',
            action: 'close'
          )
        )
      end

      it 'executes issue hooks' do
        expect(delegated_project).to receive(:execute_hooks).with(expected_payload, :issue_hooks)
        expect(delegated_project).to receive(:execute_integrations).with(expected_payload, :issue_hooks)

        described_class.new(container: delegated_project, current_user: user).close_issue(issue)
      end
    end

    context 'when issue is confidential' do
      it 'executes confidential issue hooks' do
        issue = create(:issue, :confidential, project: project)

        expect(delegated_project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(delegated_project).to receive(:execute_integrations).with(an_instance_of(Hash), :confidential_issue_hooks)

        described_class.new(container: project, current_user: user).close_issue(issue)
      end
    end

    context 'internal issues disabled' do
      before do
        project.issues_enabled = false
        project.save!
      end

      it 'does not close the issue' do
        expect(issue).to be_valid
        expect(issue).to be_opened
        expect(todo.reload).to be_pending
      end
    end
  end
end

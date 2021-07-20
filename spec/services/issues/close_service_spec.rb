# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CloseService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, email: "user@example.com") }
  let(:user2) { create(:user, email: "user2@example.com") }
  let(:guest) { create(:user) }
  let(:issue) { create(:issue, title: "My issue", project: project, assignees: [user2], author: create(:user)) }
  let(:external_issue) { ExternalIssue.new('JIRA-123', project) }
  let(:closing_merge_request) { create(:merge_request, source_project: project) }
  let(:closing_commit) { create(:commit, project: project) }
  let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_guest(guest)
  end

  describe '#execute' do
    let(:service) { described_class.new(project: project, current_user: user) }

    it 'checks if the user is authorized to update the issue' do
      expect(service).to receive(:can?).with(user, :update_issue, issue)
        .and_call_original

      service.execute(issue)
    end

    it 'does not close the issue when the user is not authorized to do so' do
      allow(service).to receive(:can?).with(user, :update_issue, issue)
        .and_return(false)

      expect(service).not_to receive(:close_issue)
      expect(service.execute(issue)).to eq(issue)
    end

    it 'closes the external issue even when the user is not authorized to do so' do
      allow(service).to receive(:can?).with(user, :update_issue, external_issue)
        .and_return(false)

      expect(service).to receive(:close_issue)
        .with(external_issue, closed_via: nil, notifications: true, system_note: true)

      service.execute(external_issue)
    end

    it 'closes the issue when the user is authorized to do so' do
      allow(service).to receive(:can?).with(user, :update_issue, issue)
        .and_return(true)

      expect(service).to receive(:close_issue)
        .with(issue, closed_via: nil, notifications: true, system_note: true)

      service.execute(issue)
    end

    it 'refreshes the number of open issues', :use_clean_rails_memory_store_caching do
      expect { service.execute(issue) }
        .to change { project.open_issues_count }.from(1).to(0)
    end

    it 'invalidates counter cache for assignees' do
      expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts)

      service.execute(issue)
    end

    context 'issue is incident type' do
      let(:issue) { create(:incident, project: project) }
      let(:current_user) { user }

      subject { service.execute(issue) }

      it_behaves_like 'an incident management tracked event', :incident_management_incident_closed
    end
  end

  describe '#close_issue' do
    context 'with external issue' do
      context 'with an active external issue tracker supporting close_issue' do
        let!(:external_issue_tracker) { create(:jira_integration, project: project) }

        it 'closes the issue on the external issue tracker' do
          project.reload
          expect(project.external_issue_tracker).to receive(:close_issue)

          described_class.new(project: project, current_user: user).close_issue(external_issue)
        end
      end

      context 'with inactive external issue tracker supporting close_issue' do
        let!(:external_issue_tracker) { create(:jira_integration, project: project, active: false) }

        it 'does not close the issue on the external issue tracker' do
          project.reload
          expect(project.external_issue_tracker).not_to receive(:close_issue)

          described_class.new(project: project, current_user: user).close_issue(external_issue)
        end
      end

      context 'with an active external issue tracker not supporting close_issue' do
        let!(:external_issue_tracker) { create(:bugzilla_integration, project: project) }

        it 'does not close the issue on the external issue tracker' do
          project.reload
          expect(project.external_issue_tracker).not_to receive(:close_issue)

          described_class.new(project: project, current_user: user).close_issue(external_issue)
        end
      end
    end

    context "closed by a merge request", :sidekiq_might_not_need_inline do
      subject(:close_issue) do
        perform_enqueued_jobs do
          described_class.new(project: project, current_user: user).close_issue(issue, closed_via: closing_merge_request)
        end
      end

      it 'mentions closure via a merge request' do
        close_issue

        email = ActionMailer::Base.deliveries.last

        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(issue.title)
        expect(email.body.parts.map(&:body)).to all(include(closing_merge_request.to_reference))
      end

      it_behaves_like 'records an onboarding progress action', :issue_auto_closed do
        let(:namespace) { project.namespace }
      end

      context 'when user cannot read merge request' do
        it 'does not mention merge request' do
          project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)

          close_issue

          email = ActionMailer::Base.deliveries.last
          body_text = email.body.parts.map(&:body).join(" ")

          expect(email.to.first).to eq(user2.email)
          expect(email.subject).to include(issue.title)
          expect(body_text).not_to include(closing_merge_request.to_reference)
        end
      end

      context 'updating `metrics.first_mentioned_in_commit_at`' do
        context 'when `metrics.first_mentioned_in_commit_at` is not set' do
          it 'uses the first commit authored timestamp' do
            expected = closing_merge_request.commits.first.authored_date

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
        perform_enqueued_jobs do
          described_class.new(project: project, current_user: user).close_issue(issue, closed_via: closing_commit)
        end

        email = ActionMailer::Base.deliveries.last

        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(issue.title)
        expect(email.body.parts.map(&:body)).to all(include(closing_commit.id))
      end

      context 'when user cannot read the commit' do
        it 'does not mention the commit id' do
          project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)
          perform_enqueued_jobs do
            described_class.new(project: project, current_user: user).close_issue(issue, closed_via: closing_commit)
          end

          email = ActionMailer::Base.deliveries.last
          body_text = email.body.parts.map(&:body).join(" ")

          expect(email.to.first).to eq(user2.email)
          expect(email.subject).to include(issue.title)
          expect(body_text).not_to include(closing_commit.id)
        end
      end
    end

    context "valid params" do
      subject(:close_issue) do
        perform_enqueued_jobs do
          described_class.new(project: project, current_user: user).close_issue(issue)
        end
      end

      it 'verifies the number of queries' do
        recorded = ActiveRecord::QueryRecorder.new { close_issue }
        expected_queries = 24

        expect(recorded.count).to be <= expected_queries
        expect(recorded.cached_count).to eq(0)
      end

      it 'closes the issue' do
        close_issue

        expect(issue).to be_valid
        expect(issue).to be_closed
      end

      it 'records closed user' do
        close_issue

        expect(issue.reload.closed_by_id).to be(user.id)
      end

      it 'sends email to user2 about assign of new issue', :sidekiq_might_not_need_inline do
        close_issue

        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(issue.title)
      end

      it 'creates resource state event about the issue being closed' do
        close_issue

        event = issue.resource_state_events.last
        expect(event.state).to eq('closed')
      end

      it 'marks todos as done' do
        close_issue

        expect(todo.reload).to be_done
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
          let!(:alert) { create(:alert_management_alert, issue: issue, project: project) }

          it 'resolves an alert and sends a system note' do
            expect_next_instance_of(SystemNotes::AlertManagementService) do |notes_service|
              expect(notes_service).to receive(:closed_alert_issue).with(issue)
            end

            close_issue

            expect(alert.reload.resolved?).to eq(true)
          end
        end

        context 'when alert cannot be resolved' do
          let!(:alert) { create(:alert_management_alert, :with_validation_errors, issue: issue, project: project) }

          before do
            allow(Gitlab::AppLogger).to receive(:warn).and_call_original
          end

          it 'writes a warning into the log' do
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

      it 'deletes milestone issue counters cache' do
        issue.update!(milestone: create(:milestone, project: project))

        expect_next_instance_of(Milestones::ClosedIssuesCountService, issue.milestone) do |service|
          expect(service).to receive(:delete_cache).and_call_original
        end

        close_issue
      end

      it_behaves_like 'does not record an onboarding progress action'
    end

    context 'when issue is not confidential' do
      it 'executes issue hooks' do
        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
        expect(project).to receive(:execute_integrations).with(an_instance_of(Hash), :issue_hooks)

        described_class.new(project: project, current_user: user).close_issue(issue)
      end
    end

    context 'when issue is confidential' do
      it 'executes confidential issue hooks' do
        issue = create(:issue, :confidential, project: project)

        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(project).to receive(:execute_integrations).with(an_instance_of(Hash), :confidential_issue_hooks)

        described_class.new(project: project, current_user: user).close_issue(issue)
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

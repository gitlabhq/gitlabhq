# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ReopenService do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, :closed, project: project) }

  describe '#execute' do
    context 'when user is not authorized to reopen issue' do
      before do
        guest = create(:user)
        project.add_guest(guest)

        perform_enqueued_jobs do
          described_class.new(project: project, current_user: guest).execute(issue)
        end
      end

      it 'does not reopen the issue' do
        expect(issue).to be_closed
      end
    end

    context 'when user is authorized to reopen issue' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
      end

      it 'invalidates counter cache for assignees' do
        issue.assignees << user
        expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts)

        described_class.new(project: project, current_user: user).execute(issue)
      end

      it 'refreshes the number of opened issues' do
        service = described_class.new(project: project, current_user: user)

        expect { service.execute(issue) }
          .to change { project.open_issues_count }.from(0).to(1)
      end

      it 'deletes milestone issue counters cache' do
        issue.update!(milestone: create(:milestone, project: project))

        expect_next_instance_of(Milestones::ClosedIssuesCountService, issue.milestone) do |service|
          expect(service).to receive(:delete_cache).and_call_original
        end

        described_class.new(project: project, current_user: user).execute(issue)
      end

      context 'issue is incident type' do
        let(:issue) { create(:incident, :closed, project: project) }
        let(:current_user) { user }

        subject { described_class.new(project: project, current_user: user).execute(issue) }

        it_behaves_like 'an incident management tracked event', :incident_management_incident_reopened
      end

      context 'when issue is not confidential' do
        it 'executes issue hooks' do
          expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
          expect(project).to receive(:execute_integrations).with(an_instance_of(Hash), :issue_hooks)

          described_class.new(project: project, current_user: user).execute(issue)
        end
      end

      context 'when issue is confidential' do
        it 'executes confidential issue hooks' do
          issue = create(:issue, :confidential, :closed, project: project)

          expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
          expect(project).to receive(:execute_integrations).with(an_instance_of(Hash), :confidential_issue_hooks)

          described_class.new(project: project, current_user: user).execute(issue)
        end
      end
    end
  end
end

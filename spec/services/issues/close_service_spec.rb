require 'spec_helper'

describe Issues::CloseService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:guest) { create(:user) }
  let(:issue) { create(:issue, assignees: [user2], author: create(:user)) }
  let(:project) { issue.project }
  let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

  before do
    project.add_master(user)
    project.add_developer(user2)
    project.add_guest(guest)
  end

  describe '#execute' do
    let(:service) { described_class.new(project, user) }

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

    it 'closes the issue when the user is authorized to do so' do
      allow(service).to receive(:can?).with(user, :update_issue, issue)
        .and_return(true)

      expect(service).to receive(:close_issue)
        .with(issue, commit: nil, notifications: true, system_note: true)

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
  end

  describe '#close_issue' do
    context "valid params" do
      before do
        perform_enqueued_jobs do
          described_class.new(project, user).close_issue(issue)
        end
      end

      it 'closes the issue' do
        expect(issue).to be_valid
        expect(issue).to be_closed
      end

      it 'sends email to user2 about assign of new issue' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(issue.title)
      end

      it 'creates system note about issue reassign' do
        note = issue.notes.last
        expect(note.note).to include "closed"
      end

      it 'marks todos as done' do
        expect(todo.reload).to be_done
      end
    end

    context 'when issue is not confidential' do
      it 'executes issue hooks' do
        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :issue_hooks)

        described_class.new(project, user).close_issue(issue)
      end
    end

    context 'when issue is confidential' do
      it 'executes confidential issue hooks' do
        issue = create(:issue, :confidential, project: project)

        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :confidential_issue_hooks)

        described_class.new(project, user).close_issue(issue)
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

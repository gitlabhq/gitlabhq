require 'spec_helper'

describe Issues::CloseService, services: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:guest) { create(:user) }
  let(:issue) { create(:issue, assignee: user2) }
  let(:project) { issue.project }
  let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
    project.team << [guest, :guest]
  end

  describe '#execute' do
    context "valid params" do
      before do
        perform_enqueued_jobs do
          described_class.new(project, user).execute(issue)
        end
      end

      it { expect(issue).to be_valid }
      it { expect(issue).to be_closed }

      it 'sends email to user2 about assign of new issue' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(issue.title)
      end

      it 'creates system note about issue reassign' do
        note = issue.notes.last
        expect(note.note).to include "Status changed to closed"
      end

      it 'marks todos as done' do
        expect(todo.reload).to be_done
      end
    end

    context 'current user is not authorized to close issue' do
      before do
        perform_enqueued_jobs do
          described_class.new(project, guest).execute(issue)
        end
      end

      it 'does not close the issue' do
        expect(issue).to be_open
      end
    end

    context 'when issue is not confidential' do
      it 'executes issue hooks' do
        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :issue_hooks)

        described_class.new(project, user).execute(issue)
      end
    end

    context 'when issue is confidential' do
      it 'executes confidential issue hooks' do
        issue = create(:issue, :confidential, project: project)

        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :confidential_issue_hooks)

        described_class.new(project, user).execute(issue)
      end
    end

    context 'external issue tracker' do
      before do
        allow(project).to receive(:default_issues_tracker?).and_return(false)
        described_class.new(project, user).execute(issue)
      end

      it { expect(issue).to be_valid }
      it { expect(issue).to be_opened }
      it { expect(todo.reload).to be_pending }
    end
  end
end

require 'spec_helper'

describe IssueObserver do
  let(:some_user) { double(:user, :id => 1) }
  let(:assignee) { double(:user, :id => 2) }
  let(:issue)    { double(:issue, :id => 42, :assignee => assignee) }

  before(:each) { subject.stub(:current_user).and_return(some_user) }

  subject { IssueObserver.instance }

  context 'when an issue is created' do

    it 'sends an email to the assignee' do
      Notify.should_receive(:new_issue_email).with(issue.id)

      subject.after_create(issue)
    end

    it 'does not send an email to the assignee if assignee created the issue' do
      subject.stub(:current_user).and_return(assignee)
      Notify.should_not_receive(:new_issue_email)

      subject.after_create(issue)
    end
  end

  context 'when an issue is changed' do
    before(:each) do
      issue.stub(:is_being_reassigned?).and_return(false)
      issue.stub(:is_being_closed?).and_return(false)
    end

    context 'a reassigned email' do
      it 'is sent if the issue is being reassigned' do
        issue.should_receive(:is_being_reassigned?).and_return(true)
        subject.should_receive(:send_reassigned_email).with(issue)

        subject.after_change(issue)
      end

      it 'is not sent if the issue is not being reassigned' do
        issue.should_receive(:is_being_reassigned?).and_return(false)
        subject.should_not_receive(:send_reassigned_email)

        subject.after_change(issue)
      end
    end

    context 'a status "closed" note' do
      it 'is created if the issue is being closed' do
        issue.should_receive(:is_being_closed?).and_return(true)
        Note.should_receive(:create_status_change_note).with(issue, some_user, 'closed')

        subject.after_change(issue)
      end

      it 'is not created if the issue is not being closed' do
        issue.should_receive(:is_being_closed?).and_return(false)
        Note.should_not_receive(:create_status_change_note).with(issue, some_user, 'closed')

        subject.after_change(issue)
      end
    end
  end

  describe '#send_reassigned_email' do
    let(:previous_assignee) { double(:user, :id => 3) }

    before(:each) do
      issue.stub(:assignee_id).and_return(assignee.id)
      issue.stub(:assignee_id_was).and_return(previous_assignee.id)
    end

    it 'sends a reassigned email to the previous and current assignees' do
      Notify.should_receive(:reassigned_issue_email).with(assignee.id, issue.id, previous_assignee.id)
      Notify.should_receive(:reassigned_issue_email).with(previous_assignee.id, issue.id, previous_assignee.id)

      subject.send_reassigned_email(issue)
    end

    context 'does not send an email to the user who made the reassignment' do
      it 'if the user is the assignee' do
        subject.stub(:current_user).and_return(assignee)
        Notify.should_not_receive(:reassigned_issue_email).with(assignee.id, issue.id, previous_assignee.id)

        subject.send_reassigned_email(issue)
      end
      it 'if the user is the previous assignee' do
        subject.stub(:current_user).and_return(previous_assignee)
        Notify.should_not_receive(:reassigned_issue_email).with(previous_assignee.id, issue.id, previous_assignee.id)

        subject.send_reassigned_email(issue)
      end
    end
  end
end

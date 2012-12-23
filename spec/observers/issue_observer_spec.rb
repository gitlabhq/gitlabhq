require 'spec_helper'

describe IssueObserver do
  let(:some_user) { double(:user, id: 1) }
  let(:assignee) { double(:user, id: 2) }
  let(:author) { double(:user, id: 3) }
  let(:issue)    { double(:issue, id: 42, assignee: assignee, author: author) }

  before(:each) { subject.stub(:current_user).and_return(some_user) }

  subject { IssueObserver.instance }

  describe '#after_create' do

    it 'is called when an issue is created' do
      subject.should_receive(:after_create)

      Issue.observers.enable :issue_observer do
        create(:issue, project: create(:project))
      end
    end

    it 'sends an email to the assignee' do
      Notify.should_receive(:new_issue_email).with(issue.id).
        and_return(double(deliver: true))

      subject.after_create(issue)
    end

    it 'does not send an email to the assignee if assignee created the issue' do
      subject.stub(:current_user).and_return(assignee)
      Notify.should_not_receive(:new_issue_email)

      subject.after_create(issue)
    end
  end

  context '#after_update' do
    before(:each) do
      issue.stub(:is_being_reassigned?).and_return(false)
      issue.stub(:is_being_closed?).and_return(false)
      issue.stub(:is_being_reopened?).and_return(false)
    end

    it 'is called when an issue is changed' do
      changed = create(:issue, project: create(:project))
      subject.should_receive(:after_update)

      Issue.observers.enable :issue_observer do
        changed.description = 'I changed'
        changed.save
      end
    end

    context 'a reassigned email' do
      it 'is sent if the issue is being reassigned' do
        issue.should_receive(:is_being_reassigned?).and_return(true)
        subject.should_receive(:send_reassigned_email).with(issue)

        subject.after_update(issue)
      end

      it 'is not sent if the issue is not being reassigned' do
        issue.should_receive(:is_being_reassigned?).and_return(false)
        subject.should_not_receive(:send_reassigned_email)

        subject.after_update(issue)
      end
    end

    context 'a status "closed"' do
      it 'note is created if the issue is being closed' do
        issue.should_receive(:is_being_closed?).and_return(true)
        Note.should_receive(:create_status_change_note).with(issue, some_user, 'closed')

        subject.after_update(issue)
      end

      it 'note is not created if the issue is not being closed' do
        issue.should_receive(:is_being_closed?).and_return(false)
        Note.should_not_receive(:create_status_change_note).with(issue, some_user, 'closed')

        subject.after_update(issue)
      end

      it 'notification is delivered if the issue being closed' do
        issue.stub(:is_being_closed?).and_return(true)
        Notify.should_receive(:issue_status_changed_email).twice.and_return(stub(deliver: true))
        Note.should_receive(:create_status_change_note).with(issue, some_user, 'closed')

        subject.after_update(issue)
      end

      it 'notification is not delivered if the issue not being closed' do
        issue.stub(:is_being_closed?).and_return(false)
        Notify.should_not_receive(:issue_status_changed_email)
        Note.should_not_receive(:create_status_change_note).with(issue, some_user, 'closed')

        subject.after_update(issue)
      end

      it 'notification is delivered only to author if the issue being closed' do
        issue_without_assignee = double(:issue, id: 42, author: author, assignee: nil)
        issue_without_assignee.stub(:is_being_reassigned?).and_return(false)
        issue_without_assignee.stub(:is_being_closed?).and_return(true)
        issue_without_assignee.stub(:is_being_reopened?).and_return(false)
        Notify.should_receive(:issue_status_changed_email).once.and_return(stub(deliver: true))
        Note.should_receive(:create_status_change_note).with(issue_without_assignee, some_user, 'closed')

        subject.after_update(issue_without_assignee)
      end
    end

    context 'a status "reopened"' do
      it 'note is created if the issue is being reopened' do
        issue.should_receive(:is_being_reopened?).and_return(true)
        Note.should_receive(:create_status_change_note).with(issue, some_user, 'reopened')

        subject.after_update(issue)
      end

      it 'note is not created if the issue is not being reopened' do
        issue.should_receive(:is_being_reopened?).and_return(false)
        Note.should_not_receive(:create_status_change_note).with(issue, some_user, 'reopened')

        subject.after_update(issue)
      end

      it 'notification is delivered if the issue being reopened' do
        issue.stub(:is_being_reopened?).and_return(true)
        Notify.should_receive(:issue_status_changed_email).twice.and_return(stub(deliver: true))
        Note.should_receive(:create_status_change_note).with(issue, some_user, 'reopened')

        subject.after_update(issue)
      end

      it 'notification is not delivered if the issue not being reopened' do
        issue.stub(:is_being_reopened?).and_return(false)
        Notify.should_not_receive(:issue_status_changed_email)
        Note.should_not_receive(:create_status_change_note).with(issue, some_user, 'reopened')

        subject.after_update(issue)
      end

      it 'notification is delivered only to author if the issue being reopened' do
        issue_without_assignee = double(:issue, id: 42, author: author, assignee: nil)
        issue_without_assignee.stub(:is_being_reassigned?).and_return(false)
        issue_without_assignee.stub(:is_being_closed?).and_return(false)
        issue_without_assignee.stub(:is_being_reopened?).and_return(true)
        Notify.should_receive(:issue_status_changed_email).once.and_return(stub(deliver: true))
        Note.should_receive(:create_status_change_note).with(issue_without_assignee, some_user, 'reopened')

        subject.after_update(issue_without_assignee)
      end
    end
  end

  describe '#send_reassigned_email' do
    let(:previous_assignee) { double(:user, id: 3) }

    before(:each) do
      issue.stub(:assignee_id).and_return(assignee.id)
      issue.stub(:assignee_id_was).and_return(previous_assignee.id)
    end

    def it_sends_a_reassigned_email_to(recipient)
      Notify.should_receive(:reassigned_issue_email).with(recipient, issue.id, previous_assignee.id).
        and_return(double(deliver: true))
    end

    def it_does_not_send_a_reassigned_email_to(recipient)
      Notify.should_not_receive(:reassigned_issue_email).with(recipient, issue.id, previous_assignee.id)
    end

    it 'sends a reassigned email to the previous and current assignees' do
      it_sends_a_reassigned_email_to assignee.id
      it_sends_a_reassigned_email_to previous_assignee.id

      subject.send(:send_reassigned_email, issue)
    end

    context 'does not send an email to the user who made the reassignment' do
      it 'if the user is the assignee' do
        subject.stub(:current_user).and_return(assignee)
        it_sends_a_reassigned_email_to previous_assignee.id
        it_does_not_send_a_reassigned_email_to assignee.id

        subject.send(:send_reassigned_email, issue)
      end
      it 'if the user is the previous assignee' do
        subject.stub(:current_user).and_return(previous_assignee)
        it_sends_a_reassigned_email_to assignee.id
        it_does_not_send_a_reassigned_email_to previous_assignee.id

        subject.send(:send_reassigned_email, issue)
      end
    end
  end
end

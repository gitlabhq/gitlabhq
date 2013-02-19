require 'spec_helper'

describe IssueObserver do
  let(:some_user)      { create :user }
  let(:assignee)       { create :user }
  let(:author)         { create :user }
  let(:mock_issue)     { double(:issue, id: 42, assignee: assignee, author: author) }
  let(:assigned_issue)   { create(:issue, assignee: assignee, author: author) }
  let(:unassigned_issue) { create(:issue, author: author) }
  let(:closed_assigned_issue)   { create(:closed_issue, assignee: assignee, author: author) }
  let(:closed_unassigned_issue) { create(:closed_issue, author: author) }


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
      Notify.should_receive(:new_issue_email).with(mock_issue.id)

      subject.after_create(mock_issue)
    end

    it 'does not send an email to the assignee if assignee created the issue' do
      subject.stub(:current_user).and_return(assignee)
      Notify.should_not_receive(:new_issue_email)

      subject.after_create(mock_issue)
    end
  end

  context '#after_close' do
    context 'a status "closed"' do
      it 'note is created if the issue is being closed' do
        Note.should_receive(:create_status_change_note).with(assigned_issue, some_user, 'closed')

        assigned_issue.close
      end

      it 'notification is delivered if the issue being closed' do
        Notify.should_receive(:issue_status_changed_email).twice

        assigned_issue.close
      end

      it 'notification is delivered only to author if the issue being closed' do
        Notify.should_receive(:issue_status_changed_email).once
        Note.should_receive(:create_status_change_note).with(unassigned_issue, some_user, 'closed')

        unassigned_issue.close
      end
    end

    context 'a status "reopened"' do
      it 'note is created if the issue is being reopened' do
        Note.should_receive(:create_status_change_note).with(closed_assigned_issue, some_user, 'reopened')

        closed_assigned_issue.reopen
      end

      it 'notification is delivered if the issue being reopened' do
        Notify.should_receive(:issue_status_changed_email).twice

        closed_assigned_issue.reopen
      end

      it 'notification is delivered only to author if the issue being reopened' do
        Notify.should_receive(:issue_status_changed_email).once
        Note.should_receive(:create_status_change_note).with(closed_unassigned_issue, some_user, 'reopened')

        closed_unassigned_issue.reopen
      end
    end
  end

  context '#after_update' do
    before(:each) do
      mock_issue.stub(:is_being_reassigned?).and_return(false)
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
        mock_issue.should_receive(:is_being_reassigned?).and_return(true)
        subject.should_receive(:send_reassigned_email).with(mock_issue)

        subject.after_update(mock_issue)
      end

      it 'is not sent if the issue is not being reassigned' do
        mock_issue.should_receive(:is_being_reassigned?).and_return(false)
        subject.should_not_receive(:send_reassigned_email)

        subject.after_update(mock_issue)
      end
    end
  end

  describe '#send_reassigned_email' do
    let(:previous_assignee) { double(:user, id: 3) }

    before(:each) do
      mock_issue.stub(:assignee_id).and_return(assignee.id)
      mock_issue.stub(:assignee_id_was).and_return(previous_assignee.id)
    end

    def it_sends_a_reassigned_email_to(recipient)
      Notify.should_receive(:reassigned_issue_email).with(recipient, mock_issue.id, previous_assignee.id)
    end

    def it_does_not_send_a_reassigned_email_to(recipient)
      Notify.should_not_receive(:reassigned_issue_email).with(recipient, mock_issue.id, previous_assignee.id)
    end

    it 'sends a reassigned email to the previous and current assignees' do
      it_sends_a_reassigned_email_to assignee.id
      it_sends_a_reassigned_email_to previous_assignee.id

      subject.send(:send_reassigned_email, mock_issue)
    end

    context 'does not send an email to the user who made the reassignment' do
      it 'if the user is the assignee' do
        subject.stub(:current_user).and_return(assignee)
        it_sends_a_reassigned_email_to previous_assignee.id
        it_does_not_send_a_reassigned_email_to assignee.id

        subject.send(:send_reassigned_email, mock_issue)
      end
      it 'if the user is the previous assignee' do
        subject.stub(:current_user).and_return(previous_assignee)
        it_sends_a_reassigned_email_to assignee.id
        it_does_not_send_a_reassigned_email_to previous_assignee.id

        subject.send(:send_reassigned_email, mock_issue)
      end
    end
  end
end

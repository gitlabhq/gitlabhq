require 'spec_helper'

describe IssueObserver do
  let(:some_user)      { create :user }
  let(:assignee)       { create :user }
  let(:author)         { create :user }
  let(:mock_issue)     { create(:issue, assignee: assignee, author: author) }


  before { subject.stub(:current_user).and_return(some_user) }
  before { subject.stub(notification: mock('NotificationService').as_null_object) }


  subject { IssueObserver.instance }

  describe '#after_create' do
    it 'trigger notification to send emails' do
      subject.should_receive(:notification)

      subject.after_create(mock_issue)
    end
  end

  context '#after_close' do
    context 'a status "closed"' do
      before { mock_issue.stub(state: 'closed') }

      it 'note is created if the issue is being closed' do
        Note.should_receive(:create_status_change_note).with(mock_issue, mock_issue.project, some_user, 'closed')

        subject.after_close(mock_issue, nil)
      end

      it 'trigger notification to send emails' do
        subject.notification.should_receive(:close_issue).with(mock_issue, some_user)
        subject.after_close(mock_issue, nil)
      end
    end

    context 'a status "reopened"' do
      before { mock_issue.stub(state: 'reopened') }

      it 'note is created if the issue is being reopened' do
        Note.should_receive(:create_status_change_note).with(mock_issue, mock_issue.project, some_user, 'reopened')
        subject.after_reopen(mock_issue, nil)
      end
    end
  end

  context '#after_update' do
    before(:each) do
      mock_issue.stub(:is_being_reassigned?).and_return(false)
    end

    context 'notification' do
      it 'triggered if the issue is being reassigned' do
        mock_issue.should_receive(:is_being_reassigned?).and_return(true)
        subject.should_receive(:notification)

        subject.after_update(mock_issue)
      end

      it 'is not triggered if the issue is not being reassigned' do
        mock_issue.should_receive(:is_being_reassigned?).and_return(false)
        subject.should_not_receive(:notification)

        subject.after_update(mock_issue)
      end
    end
  end
end

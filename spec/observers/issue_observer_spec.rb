require 'spec_helper'

describe IssueObserver do
  let(:some_user)      { create :user }
  let(:assignee)       { create :user }
  let(:author)         { create :user }
  let(:mock_issue)     { create(:issue, assignee: assignee, author: author) }


  before { subject.stub(:current_user).and_return(some_user) }
  before { subject.stub(:current_commit).and_return(nil) }
  before { subject.stub(notification: double('NotificationService').as_null_object) }
  before { mock_issue.project.stub_chain(:repository, :commit).and_return(nil) }

  subject { IssueObserver.instance }

  describe '#after_create' do
    it 'trigger notification to send emails' do
      subject.should_receive(:notification)

      subject.after_create(mock_issue)
    end

    it 'should create cross-reference notes' do
      other_issue = create(:issue)
      mock_issue.stub(references: [other_issue])

      Note.should_receive(:create_cross_reference_note).with(other_issue, mock_issue,
        some_user, mock_issue.project)
      subject.after_create(mock_issue)
    end
  end

  context '#after_close' do
    context 'a status "closed"' do
      before { mock_issue.stub(state: 'closed') }

      it 'note is created if the issue is being closed' do
        Note.should_receive(:create_status_change_note).with(mock_issue, mock_issue.project, some_user, 'closed', nil)

        subject.after_close(mock_issue, nil)
      end

      it 'trigger notification to send emails' do
        subject.notification.should_receive(:close_issue).with(mock_issue, some_user)
        subject.after_close(mock_issue, nil)
      end

      it 'appends a mention to the closing commit if one is present' do
        commit = double('commit', gfm_reference: 'commit 123456')
        subject.stub(current_commit: commit)

        Note.should_receive(:create_status_change_note).with(mock_issue, mock_issue.project, some_user, 'closed', commit)

        subject.after_close(mock_issue, nil)
      end
    end

    context 'a status "reopened"' do
      before { mock_issue.stub(state: 'reopened') }

      it 'note is created if the issue is being reopened' do
        Note.should_receive(:create_status_change_note).with(mock_issue, mock_issue.project, some_user, 'reopened', nil)

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

    context 'cross-references' do
      it 'notices added references' do
        mock_issue.should_receive(:notice_added_references)

        subject.after_update(mock_issue)
      end
    end
  end
end

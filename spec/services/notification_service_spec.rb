require 'spec_helper'

describe NotificationService do
  # Disable observers to prevent factory trigger notification service
  before { ActiveRecord::Base.observers.disable :all }

  let(:notification) { NotificationService.new }

  describe 'Keys' do
    describe :new_key do
      let(:key) { create(:personal_key) }

      it { notification.new_key(key).should be_true }

      it 'should sent email to key owner' do
        Notify.should_receive(:new_ssh_key_email).with(key.id)
        notification.new_key(key)
      end
    end
  end

  describe 'Issues' do
    let(:issue) { create :issue, assignee: create(:user) }

    describe :new_issue do
      it 'should sent email to issue assignee' do
        Notify.should_receive(:new_issue_email).with(issue.id)
        notification.new_issue(issue, nil)
      end
    end

    describe :reassigned_issue do
      it 'should sent email to issue old assignee and new issue assignee' do
        Notify.should_receive(:reassigned_issue_email)
        notification.reassigned_issue(issue, issue.author)
      end
    end

    describe :close_issue do
      it 'should sent email to issue assignee and issue author' do
        Notify.should_receive(:issue_status_changed_email)
        notification.close_issue(issue, issue.author)
      end
    end
  end
end

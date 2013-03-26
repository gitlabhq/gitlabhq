require 'spec_helper'

describe NotificationService do
  # Disable observers to prevent factory trigger notification service
  before(:all) { ActiveRecord::Base.observers.disable :all }
  after(:all) { ActiveRecord::Base.observers.enable :all }

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

  describe 'Merge Requests' do
    let(:merge_request) { create :merge_request, assignee: create(:user) }

    describe :new_merge_request do
      it 'should send email to merge_request assignee' do
        Notify.should_receive(:new_merge_request_email).with(merge_request.id)
        notification.new_merge_request(merge_request, merge_request.author)
      end

      it 'should not send email to merge_request assignee if he is current_user' do
        Notify.should_not_receive(:new_merge_request_email).with(merge_request.id)
        notification.new_merge_request(merge_request, merge_request.assignee)
      end
    end
  end
end

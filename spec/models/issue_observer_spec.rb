require 'spec_helper'

describe IssueObserver do
  let(:some_user) { Factory.new(:user, :id => 1) }
  let(:assignee) { Factory.new(:user, :id => 2) }
  let(:issue)    { Factory.new(:issue, :id => 42, :assignee => assignee) }

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

  context 'when an issue is modified' do
    it 'but not reassigned, does not send a reassigned email' do
      issue.stub(:assignee_id_changed?).and_return(false)
      Notify.should_not_receive(:reassigned_issue_email)

      subject.after_change(issue)
    end

    context 'and is reassigned' do
      let(:previous_assignee) { Factory.new(:user, :id => 3) }

      before(:each) do
        issue.stub(:assignee_id_changed?).and_return(true)
        issue.stub(:assignee_id_was).and_return(previous_assignee.id)
      end

      it 'sends a reassigned email to the previous and current assignees' do
        Notify.should_receive(:reassigned_issue_email).with(assignee.id, issue.id, previous_assignee.id)
        Notify.should_receive(:reassigned_issue_email).with(previous_assignee.id, issue.id, previous_assignee.id)

        subject.after_change(issue)
      end

      context 'does not send an email to the user who made the reassignment' do
        it 'if the user is the assignee' do
          subject.stub(:current_user).and_return(assignee)
          Notify.should_not_receive(:reassigned_issue_email).with(assignee.id, issue.id, previous_assignee.id)

          subject.after_change(issue)
        end
        it 'if the user is the previous assignee' do
          subject.stub(:current_user).and_return(previous_assignee)
          Notify.should_not_receive(:reassigned_issue_email).with(previous_assignee.id, issue.id, previous_assignee.id)

          subject.after_change(issue)
        end
      end
    end
  end
end

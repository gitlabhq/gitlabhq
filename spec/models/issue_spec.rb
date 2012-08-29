require 'spec_helper'

describe Issue do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author) }
    it { should belong_to(:assignee) }
    it { should belong_to(:milestone) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author_id) }
    it { should validate_presence_of(:project_id) }
  end

  describe "Scope" do
    it { Issue.should respond_to :closed }
    it { Issue.should respond_to :opened }
  end

  describe 'modules' do
    it { should include_module(IssueCommonality) }
    it { should include_module(Upvote) }
  end

  subject { Factory.create(:issue) }

  describe '#is_being_reassigned?' do
    it 'returns true if the issue assignee has changed' do
      subject.assignee = Factory(:user)
      subject.is_being_reassigned?.should be_true
    end
    it 'returns false if the issue assignee has not changed' do
      subject.is_being_reassigned?.should be_false
    end
  end

  describe '#is_being_closed?' do
    it 'returns true if the closed attribute has changed and is now true' do
      subject.closed = true
      subject.is_being_closed?.should be_true
    end
    it 'returns false if the closed attribute has changed and is now false' do
      issue = Factory.create(:closed_issue)
      issue.closed = false
      issue.is_being_closed?.should be_false
    end
    it 'returns false if the closed attribute has not changed' do
      subject.is_being_closed?.should be_false
    end
  end


  describe '#is_being_reopened?' do
    it 'returns true if the closed attribute has changed and is now false' do
      issue = Factory.create(:closed_issue)
      issue.closed = false
      issue.is_being_reopened?.should be_true
    end
    it 'returns false if the closed attribute has changed and is now true' do
      subject.closed = true
      subject.is_being_reopened?.should be_false
    end
    it 'returns false if the closed attribute has not changed' do
      subject.is_being_reopened?.should be_false
    end
  end
end
# == Schema Information
#
# Table name: issues
#
#  id           :integer(4)      not null, primary key
#  title        :string(255)
#  assignee_id  :integer(4)
#  author_id    :integer(4)
#  project_id   :integer(4)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  closed       :boolean(1)      default(FALSE), not null
#  position     :integer(4)      default(0)
#  critical     :boolean(1)      default(FALSE), not null
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer(4)
#


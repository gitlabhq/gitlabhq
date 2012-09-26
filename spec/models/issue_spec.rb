require 'spec_helper'

describe Issue do
  describe "Associations" do
    it { should belong_to(:milestone) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:author_id) }
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe "Validation" do
    it { should ensure_length_of(:description).is_within(0..2000) }
    it { should ensure_inclusion_of(:closed).in_array([true, false]) }
  end

  describe 'modules' do
    it { should include_module(IssueCommonality) }
    it { should include_module(Votes) }
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

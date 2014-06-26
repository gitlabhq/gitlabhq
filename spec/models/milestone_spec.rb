# == Schema Information
#
# Table name: milestones
#
#  id          :integer          not null, primary key
#  title       :string(255)      not null
#  project_id  :integer          not null
#  description :text
#  due_date    :date
#  created_at  :datetime
#  updated_at  :datetime
#  state       :string(255)
#  iid         :integer
#

require 'spec_helper'

describe Milestone do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should have_many(:issues) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    before { subject.stub(set_iid: false) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:project) }
  end

  let(:milestone) { create(:milestone) }
  let(:issue) { create(:issue) }

  describe "#percent_complete" do
    it "should not count open issues" do
      milestone.issues << issue
      milestone.percent_complete.should == 0
    end

    it "should count closed issues" do
      issue.close
      milestone.issues << issue
      milestone.percent_complete.should == 100
    end

    it "should recover from dividing by zero" do
      milestone.issues.should_receive(:count).and_return(0)
      milestone.percent_complete.should == 100
    end
  end

  describe "#expires_at" do
    it "should be nil when due_date is unset" do
      milestone.update_attributes(due_date: nil)
      milestone.expires_at.should be_nil
    end

    it "should not be nil when due_date is set" do
      milestone.update_attributes(due_date: Date.tomorrow)
      milestone.expires_at.should be_present
    end
  end

  describe :expired? do
    context "expired" do
      before do
        milestone.stub(due_date: Date.today.prev_year)
      end

      it { milestone.expired?.should be_true }
    end

    context "not expired" do
      before do
        milestone.stub(due_date: Date.today.next_year)
      end

      it { milestone.expired?.should be_false }
    end
  end

  describe :percent_complete do
    before do
      milestone.stub(
        closed_items_count: 3,
        total_items_count: 4
      )
    end

    it { milestone.percent_complete.should == 75 }
  end

  describe :items_count do
    before do
      milestone.issues << create(:issue)
      milestone.issues << create(:closed_issue)
      milestone.merge_requests << create(:merge_request)
    end

    it { milestone.closed_items_count.should == 1 }
    it { milestone.open_items_count.should == 2 }
    it { milestone.total_items_count.should == 3 }
    it { milestone.is_empty?.should be_false }
  end

  describe :can_be_closed? do
    it { milestone.can_be_closed?.should be_true }
  end

  describe :is_empty? do
    before do
      issue = create :closed_issue, milestone: milestone
      merge_request = create :merge_request, milestone: milestone
    end

    it 'Should return total count of issues and merge requests assigned to milestone' do
      milestone.total_items_count.should eq 2
    end
  end

  describe :can_be_closed? do
    before do
      milestone = create :milestone
      create :closed_issue, milestone: milestone

      issue = create :issue
    end

    it 'should be true if milestone active and all nested issues closed' do
      milestone.can_be_closed?.should be_true
    end

    it 'should be false if milestone active and not all nested issues closed' do
      issue.milestone = milestone
      issue.save

      milestone.can_be_closed?.should be_false
    end
  end

end

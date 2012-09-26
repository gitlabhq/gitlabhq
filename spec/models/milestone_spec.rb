require 'spec_helper'

describe Milestone do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should have_many(:issues) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:project_id) }
    it { should ensure_inclusion_of(:closed).in_array([true, false]) }
  end

  let(:milestone) { Factory :milestone }
  let(:issue) { Factory :issue }

  describe "#percent_complete" do
    it "should not count open issues" do
      milestone.issues << issue
      milestone.percent_complete.should == 0
    end

    it "should count closed issues" do
      issue.update_attributes(closed: true)
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
end

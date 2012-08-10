# == Schema Information
#
# Table name: milestones
#
#  id          :integer(4)      not null, primary key
#  title       :string(255)     not null
#  project_id  :integer(4)      not null
#  description :text
#  due_date    :date
#  closed      :boolean(1)      default(FALSE), not null
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#

require 'spec_helper'

describe Milestone do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should have_many(:issues) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:project_id) }
  end

  let(:project) { Factory :project }
  let(:milestone) { Factory :milestone, project: project }
  let(:issue) { Factory :issue, project: project }

  it { milestone.should be_valid }

  describe "Issues" do 
    before do 
      milestone.issues << issue
    end

    it { milestone.percent_complete.should == 0 }

    it do 
      issue.update_attributes closed: true
      milestone.percent_complete.should == 100
    end
  end

  describe :expires_at do 
    before do 
      milestone.update_attributes due_date: Date.today + 1.day
    end

    it { milestone.expires_at.should_not be_nil }
  end
end

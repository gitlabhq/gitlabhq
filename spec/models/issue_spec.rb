require 'spec_helper'

describe Issue do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author) }
    it { should belong_to(:assignee) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author_id) }
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:assignee_id) }
  end

  describe "Scope" do
    it { Issue.should respond_to :closed }
    it { Issue.should respond_to :opened }
  end

  it { Factory.create(:issue,
                      :author => Factory(:user),
                      :assignee => Factory(:user),
                      :project => Factory.create(:project)).should be_valid }

end
# == Schema Information
#
# Table name: issues
#
#  id          :integer         not null, primary key
#  title       :string(255)
#  assignee_id :integer
#  author_id   :integer
#  project_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#  closed      :boolean         default(FALSE), not null
#  position    :integer         default(0)
#  critical    :boolean         default(FALSE), not null
#  branch_name :string(255)
#


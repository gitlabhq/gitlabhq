require 'spec_helper'

describe MergeRequest do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author) }
    it { should belong_to(:assignee) }
  end

  describe "Validation" do
    it { should validate_presence_of(:target_branch) }
    it { should validate_presence_of(:source_branch) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author_id) }
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:assignee_id) }
  end

  describe "Scope" do
    it { MergeRequest.should respond_to :closed }
    it { MergeRequest.should respond_to :opened }
  end

  it { Factory.create(:merge_request,
                      :author => Factory(:user),
                      :assignee => Factory(:user),
                      :project => Factory.create(:project)).should be_valid }
end
# == Schema Information
#
# Table name: merge_requests
#
#  id            :integer         not null, primary key
#  target_branch :string(255)     not null
#  source_branch :string(255)     not null
#  project_id    :integer         not null
#  author_id     :integer
#  assignee_id   :integer
#  title         :string(255)
#  closed        :boolean         default(FALSE), not null
#  created_at    :datetime
#  updated_at    :datetime
#


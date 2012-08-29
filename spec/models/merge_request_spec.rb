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
  end

  describe "Scope" do
    it { MergeRequest.should respond_to :closed }
    it { MergeRequest.should respond_to :opened }
  end

  describe 'modules' do
    it { should include_module(IssueCommonality) }
    it { should include_module(Upvote) }
  end
end
# == Schema Information
#
# Table name: merge_requests
#
#  id            :integer(4)      not null, primary key
#  target_branch :string(255)     not null
#  source_branch :string(255)     not null
#  project_id    :integer(4)      not null
#  author_id     :integer(4)
#  assignee_id   :integer(4)
#  title         :string(255)
#  closed        :boolean(1)      default(FALSE), not null
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#  st_commits    :text(2147483647
#  st_diffs      :text(2147483647
#  merged        :boolean(1)      default(FALSE), not null
#  state         :integer(4)      default(1), not null
#


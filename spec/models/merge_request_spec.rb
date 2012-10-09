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
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#  st_commits    :text(4294967295
#  st_diffs      :text(4294967295
#  merged        :boolean         default(FALSE), not null
#  state         :integer         default(1), not null
#

require 'spec_helper'

describe MergeRequest do
  describe "Validation" do
    it { should validate_presence_of(:target_branch) }
    it { should validate_presence_of(:source_branch) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:author_id) }
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe 'modules' do
    it { should include_module(IssueCommonality) }
    it { should include_module(Votes) }
  end
end

require 'spec_helper'

describe MergeRequest do
  describe "Validation" do
    it { should validate_presence_of(:target_branch) }
    it { should validate_presence_of(:source_branch) }
  end

  describe 'modules' do
    it { should include_module(IssueCommonality) }
    it { should include_module(Upvote) }
  end
end

require 'spec_helper'

describe MergeRequests::PostMergeService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, assignee: user) }
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
  end

  describe '#execute' do
    it_behaves_like 'cache counters invalidator'
  end
end

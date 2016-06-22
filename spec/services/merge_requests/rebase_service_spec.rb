require 'spec_helper'

describe MergeRequests::RebaseService do
  let(:user) { create(:user) }
  let(:merge_request) do
    create(:merge_request,
           source_branch: 'feature_conflict',
           target_branch: 'master')
  end
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
  end

  describe :execute do
    context 'valid params' do
      let(:service) { MergeRequests::RebaseService.new(project, user, {}) }

      before do
        service.execute(merge_request)
      end

      it "should rebase source branch" do
        parent_sha = merge_request.source_project.repository.commit(merge_request.source_branch).parents.first.sha
        target_branch_sha = merge_request.target_project.repository.commit(merge_request.target_branch).sha
        expect(parent_sha).to eq(target_branch_sha)
      end

      it 'records the new SHA on the merge request' do
        head_sha = merge_request.source_project.repository.commit(merge_request.source_branch).sha
        expect(merge_request.reload.rebase_commit_sha).to eq(head_sha)
      end
    end
  end
end

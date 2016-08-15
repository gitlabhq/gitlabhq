require "spec_helper"

describe MergeRequests::GetUrlsService do
  let(:project) { create(:project, :public) }
  let(:service) { MergeRequests::GetUrlsService.new(project) }
  let(:source_branch) { "my_branch" }
  let(:new_merge_request_url) { "http://localhost/#{project.namespace.name}/#{project.path}/merge_requests/new?merge_request%5Bsource_branch%5D=#{source_branch}" }
  let(:show_merge_request_url) { "http://localhost/#{project.namespace.name}/#{project.path}/merge_requests/#{merge_request.iid}" }
  let(:new_branch_changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:deleted_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 #{Gitlab::Git::BLANK_SHA} refs/heads/#{source_branch}" }
  let(:existing_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:default_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master" }

  describe "#execute" do
    shared_examples 'new_merge_request_link' do
      it 'returns url to create new merge request' do
        result = service.execute(changes)
        expect(result).to match([{
          branch_name: source_branch,
          url: new_merge_request_url,
          new_merge_request: true
        }])
      end
    end

    shared_examples 'show_merge_request_url' do
      it 'returns url to view merge request' do
        result = service.execute(changes)
        expect(result).to match([{
          branch_name: source_branch,
          url: show_merge_request_url,
          new_merge_request: false
        }])
      end
    end

    shared_examples 'no_merge_request_url' do
      it 'returns no URL' do
        result = service.execute(changes)
        expect(result).to be_empty
      end
    end

    context 'pushing to default branch' do
      let(:changes) { default_branch_changes }
      it_behaves_like 'no_merge_request_url'
    end

    context 'pushing to project with MRs disabled' do
      let(:changes) { new_branch_changes }

      before do
        project.merge_requests_enabled = false
      end

      it_behaves_like 'no_merge_request_url'
    end

    context 'pushing one completely new branch' do
      let(:changes) { new_branch_changes }
      it_behaves_like 'new_merge_request_link'
    end

    context 'pushing to existing branch but no merge request' do
      let(:changes) { existing_branch_changes }
      it_behaves_like 'new_merge_request_link'
    end

    context 'pushing to deleted branch' do
      let(:changes) { deleted_branch_changes }
      it_behaves_like 'no_merge_request_url'
    end

    context 'pushing to existing branch and merge request opened' do
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }
      let(:changes) { existing_branch_changes }
      it_behaves_like 'show_merge_request_url'
    end

    context 'pushing to existing branch and merge request is reopened' do
      let!(:merge_request) { create(:merge_request, :reopened, source_project: project, source_branch: source_branch) }
      let(:changes) { existing_branch_changes }
      it_behaves_like 'show_merge_request_url'
    end

    context 'pushing to existing branch from forked project' do
      let(:user) { create(:user) }
      let!(:forked_project) { Projects::ForkService.new(project, user).execute }
      let!(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project, source_branch: source_branch) }
      let(:changes) { existing_branch_changes }
      # Source project is now the forked one
      let(:service) { MergeRequests::GetUrlsService.new(forked_project) }

      before do
        allow(forked_project).to receive(:empty_repo?).and_return(false)
      end

      it_behaves_like 'show_merge_request_url'
    end

    context 'pushing to existing branch and merge request is closed' do
      let!(:merge_request) { create(:merge_request, :closed, source_project: project, source_branch: source_branch) }
      let(:changes) { existing_branch_changes }
      it_behaves_like 'new_merge_request_link'
    end

    context 'pushing to existing branch and merge request is merged' do
      let!(:merge_request) { create(:merge_request, :merged, source_project: project, source_branch: source_branch) }
      let(:changes) { existing_branch_changes }
      it_behaves_like 'new_merge_request_link'
    end

    context 'pushing new branch and existing branch (with merge request created) at once' do
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: "existing_branch") }
      let(:new_branch_changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/new_branch" }
      let(:existing_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/existing_branch" }
      let(:changes) { "#{new_branch_changes}\n#{existing_branch_changes}" }
      let(:new_merge_request_url) { "http://localhost/#{project.namespace.name}/#{project.path}/merge_requests/new?merge_request%5Bsource_branch%5D=new_branch" }

      it 'returns 2 urls for both creating new and showing merge request' do
        result = service.execute(changes)
        expect(result).to match([{
          branch_name: "new_branch",
          url: new_merge_request_url,
          new_merge_request: true
        }, {
          branch_name: "existing_branch",
          url: show_merge_request_url,
          new_merge_request: false
        }])
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequests::GetUrlsService do
  include ProjectForksHelper

  let(:project) { create(:project, :public, :repository) }
  let(:service) { described_class.new(project: project) }
  let(:source_branch) { "merge-test" }
  let(:new_merge_request_url) { "http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/merge_requests/new?merge_request%5Bsource_branch%5D=#{source_branch}" }
  let(:show_merge_request_url) { "http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/merge_requests/#{merge_request.iid}" }
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

    context 'when project is nil' do
      let(:project) { nil }
      let(:changes) { default_branch_changes }

      it_behaves_like 'no_merge_request_url'
    end

    context 'pushing to default branch' do
      let(:changes) { default_branch_changes }

      it_behaves_like 'no_merge_request_url'
    end

    context 'pushing to project with MRs disabled' do
      let(:changes) { new_branch_changes }

      before do
        project.project_feature.update_attribute(:merge_requests_access_level, ProjectFeature::DISABLED)
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
      let!(:merge_request) { create(:merge_request, :opened, source_project: project, source_branch: source_branch) }
      let(:changes) { existing_branch_changes }

      it_behaves_like 'show_merge_request_url'
    end

    context 'pushing to existing branch from forked project' do
      let(:user) { create(:user) }
      let!(:forked_project) { fork_project(project, user, repository: true) }
      let!(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project, source_branch: source_branch) }
      let(:changes) { existing_branch_changes }
      # Source project is now the forked one
      let(:service) { described_class.new(project: forked_project) }

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
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: "markdown") }
      let(:new_branch_changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/new_branch" }
      let(:existing_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/markdown" }
      let(:changes) { "#{new_branch_changes}\n#{existing_branch_changes}" }
      let(:new_merge_request_url) { "http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/merge_requests/new?merge_request%5Bsource_branch%5D=new_branch" }

      it 'returns 2 urls for both creating new and showing merge request' do
        result = service.execute(changes)
        expect(result).to match([{
          branch_name: "new_branch",
          url: new_merge_request_url,
          new_merge_request: true
        }, {
          branch_name: "markdown",
          url: show_merge_request_url,
          new_merge_request: false
        }])
      end
    end

    context 'when printing_merge_request_link_enabled is false' do
      it 'returns empty array' do
        project.update!(printing_merge_request_link_enabled: false)

        result = service.execute(existing_branch_changes)

        expect(result).to eq([])
      end
    end
  end
end

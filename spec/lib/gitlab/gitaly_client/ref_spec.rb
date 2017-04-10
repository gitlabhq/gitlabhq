require 'spec_helper'

describe Gitlab::GitalyClient::Ref do
  let(:project) { create(:empty_project) }
  let(:repo_path) { project.repository.path_to_repo }
  let(:client) { Gitlab::GitalyClient::Ref.new(project.repository) }

  before do
    allow(Gitlab.config.gitaly).to receive(:enabled).and_return(true)
  end

  describe '#branch_names' do
    it 'sends a find_all_branch_names message' do
      expect_any_instance_of(Gitaly::Ref::Stub).
        to receive(:find_all_branch_names).with(gitaly_request_with_repo_path(repo_path)).
          and_return([])

      client.branch_names
    end
  end

  describe '#tag_names' do
    it 'sends a find_all_tag_names message' do
      expect_any_instance_of(Gitaly::Ref::Stub).
        to receive(:find_all_tag_names).with(gitaly_request_with_repo_path(repo_path)).
          and_return([])

      client.tag_names
    end
  end

  describe '#default_branch_name' do
    it 'sends a find_default_branch_name message' do
      expect_any_instance_of(Gitaly::Ref::Stub).
        to receive(:find_default_branch_name).with(gitaly_request_with_repo_path(repo_path)).
        and_return(double(name: 'foo'))

      client.default_branch_name
    end
  end
end

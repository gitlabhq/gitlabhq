require 'spec_helper'

describe Gitlab::GitalyClient::Ref do
  let(:project) { create(:empty_project) }
  let(:repo_path) { project.repository.path_to_repo }
  let(:client) { described_class.new(project.repository) }

  before do
    allow(Gitlab.config.gitaly).to receive(:enabled).and_return(true)
  end

  after do
    # When we say `expect_any_instance_of(Gitaly::Ref::Stub)` a double is created,
    # and because GitalyClient shares stubs these will get passed from example to
    # example, which will cause an error, so we clean the stubs after each example.
    Gitlab::GitalyClient.clear_stubs!
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

  describe '#local_branches' do
    it 'sends a find_local_branches message' do
      expect_any_instance_of(Gitaly::Ref::Stub).
        to receive(:find_local_branches).with(gitaly_request_with_repo_path(repo_path)).
          and_return([])

      client.local_branches
    end

    it 'parses and sends the sort parameter' do
      expect_any_instance_of(Gitaly::Ref::Stub).
        to receive(:find_local_branches).
          with(gitaly_request_with_params(sort_by: :UPDATED_DESC)).
          and_return([])

      client.local_branches(sort_by: 'updated_desc')
    end

    it 'raises an argument error if an invalid sort_by parameter is passed' do
      expect { client.local_branches(sort_by: 'invalid_sort') }.to raise_error(ArgumentError)
    end
  end
end

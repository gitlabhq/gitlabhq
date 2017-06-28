require 'spec_helper'

describe Gitlab::ImportExport::MergeRequestParser do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :test_repo, name: 'test-repo-restorer', path: 'test-repo-restorer') }
  let(:forked_from_project) { create(:project) }
  let(:fork_link) { create(:forked_project_link, forked_from_project: project) }

  let!(:merge_request) do
    create(:merge_request, source_project: fork_link.forked_to_project, target_project: project)
  end

  let(:parsed_merge_request) do
    described_class.new(project,
                        merge_request.diff_head_sha,
                        merge_request,
                        merge_request.as_json).parse!
  end

  after do
    FileUtils.rm_rf(project.repository.path_to_repo)
  end

  it 'has a source branch' do
    expect(project.repository.branch_exists?(parsed_merge_request.source_branch)).to be true
  end

  it 'has a target branch' do
    expect(project.repository.branch_exists?(parsed_merge_request.target_branch)).to be true
  end
end

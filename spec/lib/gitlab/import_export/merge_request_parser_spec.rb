# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::MergeRequestParser do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, name: 'test-repo-restorer', path: 'test-repo-restorer') }
  let(:forked_project) { fork_project(project) }

  let!(:merge_request) do
    create(:merge_request, source_project: forked_project, target_project: project)
  end

  let(:parsed_merge_request) do
    described_class.new(project,
                        'abcd',
                        merge_request,
                        merge_request.as_json).parse!
  end

  after do
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      FileUtils.rm_rf(project.repository.path_to_repo)
    end
  end

  it 'has a source branch' do
    expect(project.repository.branch_exists?(parsed_merge_request.source_branch)).to be true
  end

  it 'has a target branch' do
    expect(project.repository.branch_exists?(parsed_merge_request.target_branch)).to be true
  end

  it 'parses a MR that has no source branch' do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:branch_exists?).and_call_original
      allow(instance).to receive(:branch_exists?).with(merge_request.source_branch).and_return(false)
      allow(instance).to receive(:fork_merge_request?).and_return(true)
    end
    allow(Gitlab::GitalyClient).to receive(:migrate).and_call_original
    allow(Gitlab::GitalyClient).to receive(:migrate).with(:fetch_ref).and_return([nil, 0])

    expect(parsed_merge_request).to eq(merge_request)
  end

  context 'when the merge request has diffs' do
    let(:merge_request) do
      build(:merge_request, source_project: forked_project, target_project: project)
    end

    context 'when the diff is invalid' do
      let(:merge_request_diff) { build(:merge_request_diff, merge_request: merge_request, base_commit_sha: 'foobar') }

      it 'sets the diff to nil' do
        expect(merge_request_diff).to be_invalid
        expect(merge_request_diff.merge_request).to eq merge_request
        expect(parsed_merge_request.merge_request_diff).to be_nil
      end
    end
  end
end

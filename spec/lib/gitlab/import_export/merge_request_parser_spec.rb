# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::MergeRequestParser, feature_category: :importers do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, name: 'test-repo-restorer', path: 'test-repo-restorer') }
  let(:forked_project) { fork_project(project) }

  let!(:merge_request) do
    create(:merge_request, source_project: forked_project, target_project: project)
  end

  let(:diff_head_sha) { SecureRandom.hex(20) }

  let(:parsed_merge_request) do
    described_class.new(
      project,
      diff_head_sha,
      merge_request,
      merge_request.as_json,
      user: user
    ).parse!
  end

  before do
    project.add_maintainer(user)
  end

  after do
    project.repository.remove
  end

  it 'has a source branch' do
    expect(project.repository.branch_exists?(parsed_merge_request.source_branch)).to be true
  end

  it 'has a target branch' do
    expect(project.repository.branch_exists?(parsed_merge_request.target_branch)).to be true
  end

  # Source and target branch are only created when: fork_merge_request
  context 'fork merge request' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:fork_merge_request?).and_return(true)
      end
    end

    it 'parses a MR that has no source branch' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:branch_exists?).and_call_original
        allow(instance).to receive(:branch_exists?).with(merge_request.source_branch).and_return(false)
      end

      expect(parsed_merge_request).to eq(merge_request)
    end

    describe 'target branch' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:branch_exists?).and_call_original
          allow(instance).to receive(:branch_exists?).with(merge_request.target_branch).and_return(false)
          allow(instance).to receive(:fork_merge_request?).and_return(true)
        end
      end

      it 'parses a MR that has no target branch' do
        expect(parsed_merge_request).to eq(merge_request)
      end

      context 'when target branch fails to be created' do
        it 'logs the error' do
          allow(project.repository).to receive(:add_branch).and_raise(StandardError, 'Error!')

          expect(::Import::Framework::Logger).to receive(:warn).with(
            message: 'Import warning: Failed to create target branch',
            target_branch: merge_request.target_branch,
            diff_head_sha: anything,
            merge_request_iid: merge_request.iid,
            Labkit::Fields::ERROR_MESSAGE => 'Error!'
          )

          expect(parsed_merge_request).to eq(merge_request)
        end
      end

      context 'when target branch name is unsafe (starts with refs/)' do
        it 'logs a distinct rejection message instead of the generic failure message' do
          merge_request.update!(target_branch: 'refs/heads/unsafe')

          expect(::Import::Framework::Logger).to receive(:warn).with(
            message: 'Import warning: Rejected unsafe branch name during import',
            branch_type: :target_branch,
            branch_name: 'refs/heads/unsafe',
            merge_request_iid: merge_request.iid,
            Labkit::Fields::ERROR_MESSAGE => anything
          )

          expect(parsed_merge_request).to eq(merge_request)
        end
      end
    end

    it 'parses a MR that is closed' do
      merge_request.update!(state: :closed, source_branch: 'new_branch')

      expect(project.repository.branch_exists?(parsed_merge_request.source_branch)).to be false
    end

    it 'parses a MR that is merged' do
      merge_request.update!(state: :merged, source_branch: 'new_branch')

      expect(project.repository.branch_exists?(parsed_merge_request.source_branch)).to be false
    end
  end

  context 'when the merge request has diffs' do
    let(:merge_request) do
      build(:merge_request, source_project: forked_project, target_project: project)
    end

    context 'when the diff is invalid' do
      let(:merge_request_diff) { build(:merge_request_diff, merge_request: merge_request, base_commit_sha: 'foobar') }

      it 'sets the diff to empty diff' do
        expect(merge_request_diff).to be_invalid
        expect(merge_request_diff.merge_request).to eq merge_request
        expect(parsed_merge_request.merge_request_diff).to be_empty
      end
    end
  end

  # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/604665.
  context 'when the payload targets an existing protected branch' do
    let!(:attacker) { create(:user) }

    let(:protected_branch_name) { project.default_branch_or_main }

    let!(:protected_branch) do
      create(:protected_branch, :no_one_can_push, :maintainers_can_merge,
        project: project, name: protected_branch_name)
    end

    let!(:legitimate_sha) { project.repository.commit(protected_branch_name).sha }

    # Simulates the attacker-controlled `diff_head_sha` from the crafted export payload.
    let!(:attacker_sha) do
      project.repository.add_branch(project.creator, 'attacker-payload', legitimate_sha)
      project.repository.create_file(
        project.creator, 'BACKDOOR', 'pwned', message: 'add backdoor', branch_name: 'attacker-payload'
      )
      sha = project.repository.commit('attacker-payload').sha
      project.repository.rm_branch(project.creator, 'attacker-payload')
      sha
    end

    let(:relation_hash) { { 'source_project_id' => nil, 'project_id' => project.id } }

    before do
      project.add_maintainer(attacker)
    end

    context 'via source_branch/diff_head_sha' do
      let(:malicious_merge_request) do
        build(:merge_request,
          source_project: project,
          target_project: project,
          source_branch: "refs/heads/#{protected_branch_name}",
          target_branch: protected_branch_name)
      end

      subject(:parse!) do
        described_class.new(project, attacker_sha, malicious_merge_request, relation_hash, user: attacker).parse!
      end

      it 'does not overwrite the protected branch with the attacker-controlled sha', :aggregate_failures do
        expect { parse! }.not_to change { project.repository.commit(protected_branch_name).sha }
        expect(project.repository.commit(protected_branch_name).sha).to eq(legitimate_sha)
      end
    end

    # target_branch_sha is independently importable, so this bypass doesn't need source_branch at all.
    context 'via target_branch/target_branch_sha' do
      let(:malicious_merge_request) do
        build(:merge_request,
          source_project: project,
          target_project: project,
          source_branch: 'feature',
          target_branch: "refs/heads/#{protected_branch_name}").tap do |mr|
          mr.target_branch_sha = attacker_sha
        end
      end

      subject(:parse!) do
        described_class.new(project, diff_head_sha, malicious_merge_request, relation_hash, user: attacker).parse!
      end

      it 'does not overwrite the protected branch with the attacker-controlled sha', :aggregate_failures do
        expect { parse! }.not_to change { project.repository.commit(protected_branch_name).sha }
        expect(project.repository.commit(protected_branch_name).sha).to eq(legitimate_sha)
      end
    end
  end
end

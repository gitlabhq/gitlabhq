require 'spec_helper'

describe 'Gitlab::Satellite::MergeAction' do
  include RepoHelpers

  let(:project) { create(:project, namespace: create(:group)) }
  let(:fork_project) { create(:project, namespace: create(:group), forked_from_project: project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:merge_request_fork) { create(:merge_request, source_project: fork_project, target_project: project) }

  let(:merge_request_with_conflict) { create(:merge_request, :conflict, source_project: project, target_project: project) }
  let(:merge_request_fork_with_conflict) { create(:merge_request, :conflict, source_project: project, target_project: project) }

  describe '#commits_between' do
    def verify_commits(commits, first_commit_sha, last_commit_sha)
      commits.each { |commit| expect(commit.class).to eq(Gitlab::Git::Commit) }
      expect(commits.first.id).to eq(first_commit_sha)
      expect(commits.last.id).to eq(last_commit_sha)
    end

    context 'on fork' do
      it 'should get proper commits between' do
        commits = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).commits_between
        verify_commits(commits, sample_compare.commits.first, sample_compare.commits.last)
      end
    end

    context 'between branches' do
      it 'should raise exception -- not expected to be used by non forks' do
        expect { Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).commits_between }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#format_patch' do
    def verify_content(patch)
      sample_compare.commits.each do |commit|
        expect(patch.include?(commit)).to be_truthy
      end
    end

    context 'on fork' do
      it 'should build a format patch' do
        patch = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).format_patch
        verify_content(patch)
      end
    end

    context 'between branches' do
      it 'should build a format patch' do
        patch = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request).format_patch
        verify_content(patch)
      end
    end
  end

  describe '#diffs_between_satellite tested against diff_in_satellite' do
    def is_a_matching_diff(diff, diffs)
      diff_count = diff.scan('diff --git').size
      expect(diff_count).to be >= 1
      expect(diffs.size).to eq(diff_count)
      diffs.each do |a_diff|
        expect(a_diff.class).to eq(Gitlab::Git::Diff)
        expect(diff.include? a_diff.diff).to be_truthy
      end
    end

    context 'on fork' do
      it 'should get proper diffs' do
        diffs = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).diffs_between_satellite
        diff = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request_fork).diff_in_satellite
        is_a_matching_diff(diff, diffs)
      end
    end

    context 'between branches' do
      it 'should get proper diffs' do
        expect{ Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).diffs_between_satellite }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#can_be_merged?' do
    context 'on fork' do
      it do
        expect(Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).can_be_merged?).to be_truthy
      end

      it do
        expect(Gitlab::Satellite::MergeAction.new(merge_request_fork_with_conflict.author, merge_request_fork_with_conflict).can_be_merged?).to be_falsey
      end
    end

    context 'between branches' do
      it do
        expect(Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).can_be_merged?).to be_truthy
      end

      it do
        expect(Gitlab::Satellite::MergeAction.new(merge_request_with_conflict.author, merge_request_with_conflict).can_be_merged?).to be_falsey
      end
    end
  end

  describe '#merge!' do
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, source_branch: "markdown", should_remove_source_branch: true) }
    let(:merge_action) { Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request) }

    it 'clears cache of source repo after removing source branch' do
      project.repository.expire_branch_names
      expect(project.repository.branch_names).to include('markdown')

      merge_action.merge!

      expect(project.repository.branch_names).not_to include('markdown')
    end
  end
end

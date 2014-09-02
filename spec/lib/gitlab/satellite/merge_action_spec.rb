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
      commits.each { |commit| commit.class.should == Gitlab::Git::Commit }
      commits.first.id.should == first_commit_sha
      commits.last.id.should == last_commit_sha
    end

    context 'on fork' do
      it 'should get proper commits between' do
        commits = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).commits_between
        verify_commits(commits, sample_compare.commits.first, sample_compare.commits.last)
      end
    end

    context 'between branches' do
      it 'should raise exception -- not expected to be used by non forks' do
        expect { Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).commits_between }.to raise_error
      end
    end
  end

  describe '#format_patch' do
    def verify_content(patch)
      sample_compare.commits.each do |commit|
        patch.include?(commit).should be_true
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
      diff_count.should >= 1
      diffs.size.should == diff_count
      diffs.each do |a_diff|
        a_diff.class.should == Gitlab::Git::Diff
        (diff.include? a_diff.diff).should be_true
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
        expect{ Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).diffs_between_satellite }.to raise_error
      end
    end
  end

  describe '#can_be_merged?' do
    context 'on fork' do
      it { Gitlab::Satellite::MergeAction.new(
        merge_request_fork.author,
        merge_request_fork).can_be_merged?.should be_true }

      it { Gitlab::Satellite::MergeAction.new(
        merge_request_fork_with_conflict.author,
        merge_request_fork_with_conflict).can_be_merged?.should be_false }
    end

    context 'between branches' do
      it { Gitlab::Satellite::MergeAction.new(
        merge_request.author,
        merge_request).can_be_merged?.should be_true }

      it { Gitlab::Satellite::MergeAction.new(
        merge_request_with_conflict.author,
        merge_request_with_conflict).can_be_merged?.should be_false }
    end
  end
end

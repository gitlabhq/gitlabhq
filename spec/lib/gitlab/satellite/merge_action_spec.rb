require 'spec_helper'

describe 'Gitlab::Satellite::MergeAction' do
  before(:each) do
    @master = ['master', '69b34b7e9ad9f496f0ad10250be37d6265a03bba']
    @one_after_stable = ['stable', '6ea87c47f0f8a24ae031c3fff17bc913889ecd00'] #this commit sha is one after stable
    @wiki_branch = ['wiki', '635d3e09b72232b6e92a38de6cc184147e5bcb41'] #this is the commit sha where the wiki branch goes off from master
    @conflicting_metior = ['metior', '313d96e42b313a0af5ab50fa233bf43e27118b3f'] #this branch conflicts with the wiki branch

    # these commits are quite close together, itended to make string diffs/format patches small
    @close_commit1 = ['2_3_notes_fix', '8470d70da67355c9c009e4401746b1d5410af2e3']
    @close_commit2 = ['scss_refactoring', 'f0f14c8eaba69ebddd766498a9d0b0e79becd633']
  end

  let(:project) { create(:project, namespace: create(:group)) }
  let(:fork_project) { create(:project, namespace: create(:group)) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:merge_request_fork) { create(:merge_request, source_project: fork_project, target_project: project) }

  describe '#commits_between' do
    def verify_commits(commits, first_commit_sha, last_commit_sha)
      commits.each { |commit| commit.class.should == Gitlab::Git::Commit }
      commits.first.id.should == first_commit_sha
      commits.last.id.should == last_commit_sha
    end

    context 'on fork' do
      it 'should get proper commits between' do
        merge_request_fork.target_branch = @one_after_stable[0]
        merge_request_fork.source_branch = @master[0]
        commits = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).commits_between
        verify_commits(commits, @one_after_stable[1], @master[1])

        merge_request_fork.target_branch = @wiki_branch[0]
        merge_request_fork.source_branch = @master[0]
        commits = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).commits_between
        verify_commits(commits, @wiki_branch[1], @master[1])
      end
    end

    context 'between branches' do
      it 'should raise exception -- not expected to be used by non forks' do
        merge_request.target_branch = @one_after_stable[0]
        merge_request.source_branch = @master[0]
        expect {Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).commits_between}.to raise_error

        merge_request.target_branch = @wiki_branch[0]
        merge_request.source_branch = @master[0]
        expect {Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).commits_between}.to raise_error
      end
    end
  end

  describe '#format_patch' do
    let(:target_commit) {['artiom-config-examples','9edbac5ac88ffa1ec9dad0097226b51e29ebc9ac']}
    let(:source_commit) {['metior', '313d96e42b313a0af5ab50fa233bf43e27118b3f']}

    def verify_content(patch)
      (patch.include? source_commit[1]).should be_true
      (patch.include? '635d3e09b72232b6e92a38de6cc184147e5bcb41').should be_true
      (patch.include? '2bb2dee057327c81978ed0aa99904bd7ff5e6105').should be_true
      (patch.include? '2e83de1924ad3429b812d17498b009a8b924795d').should be_true
      (patch.include? 'ee45a49c57a362305431cbf004e4590b713c910e').should be_true
      (patch.include? 'a6870dd08f8f274d9a6b899f638c0c26fefaa690').should be_true

      (patch.include? 'e74fae147abc7d2ffbf93d363dbbe45b87751f6f').should be_false
      (patch.include? '86f76b11c670425bbab465087f25172378d76147').should be_false
    end

    context 'on fork' do
      it 'should build a format patch' do
        merge_request_fork.target_branch = target_commit[0]
        merge_request_fork.source_branch = source_commit[0]
        patch = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).format_patch
        verify_content(patch)
      end
    end

    context 'between branches' do
      it 'should build a format patch' do
        merge_request.target_branch = target_commit[0]
        merge_request.source_branch = source_commit[0]
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
        merge_request_fork.target_branch = @close_commit1[0]
        merge_request_fork.source_branch = @master[0]
        diffs = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).diffs_between_satellite

        merge_request_fork.target_branch = @close_commit1[0]
        merge_request_fork.source_branch = @master[0]
        diff = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request_fork).diff_in_satellite

        is_a_matching_diff(diff, diffs)
      end
    end

    context 'between branches' do
      it 'should get proper diffs' do
        merge_request.target_branch = @close_commit1[0]
        merge_request.source_branch = @master[0]
        expect{Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).diffs_between_satellite}.to raise_error
      end
    end
  end

  describe '#can_be_merged?' do
    context 'on fork' do
      it 'return true or false depending on if something is mergable' do
        merge_request_fork.target_branch = @one_after_stable[0]
        merge_request_fork.source_branch = @master[0]
        Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).can_be_merged?.should be_true

        merge_request_fork.target_branch = @conflicting_metior[0]
        merge_request_fork.source_branch = @wiki_branch[0]
        Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).can_be_merged?.should be_false
      end
    end

    context 'between branches' do
      it 'return true or false depending on if something is mergable' do
        merge_request.target_branch = @one_after_stable[0]
        merge_request.source_branch = @master[0]
        Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).can_be_merged?.should be_true

        merge_request.target_branch = @conflicting_metior[0]
        merge_request.source_branch = @wiki_branch[0]
        Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).can_be_merged?.should be_false
      end
    end
  end
end

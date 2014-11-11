require 'spec_helper'

describe MergeRequests::RefreshService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { MergeRequests::RefreshService }

  describe :execute do
    before do
      @user = create(:user)
      group = create(:group)
      group.add_owner(@user)

      @project = create(:project, namespace: group)
      @fork_project = Projects::ForkService.new(@project, @user).execute
      @merge_request = create(:merge_request, source_project: @project,
                              source_branch: 'master',
                              target_branch: 'feature',
                              target_project: @project)

      @fork_merge_request = create(:merge_request, source_project: @fork_project,
                                   source_branch: 'master',
                                   target_branch: 'feature',
                                   target_project: @project)

      @commits = @merge_request.commits

      @oldrev = @commits.last.id
      @newrev = @commits.first.id
    end

    context 'push to origin repo source branch' do
      before do
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it { @merge_request.notes.should_not be_empty }
      it { @merge_request.should be_open }
      it { @fork_merge_request.should be_open }
      it { @fork_merge_request.notes.should be_empty }
    end

    context 'push to origin repo target branch' do
      before do
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { @merge_request.notes.should be_empty }
      it { @merge_request.should be_merged }
      it { @fork_merge_request.should be_merged }
      it { @fork_merge_request.notes.should be_empty }
    end

    context 'push to fork repo source branch' do
      before do
        service.new(@fork_project, @user).execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it { @merge_request.notes.should be_empty }
      it { @merge_request.should be_open }
      it { @fork_merge_request.notes.should_not be_empty }
      it { @fork_merge_request.should be_open }
    end

    context 'push to fork repo target branch' do
      before do
        service.new(@fork_project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { @merge_request.notes.should be_empty }
      it { @merge_request.should be_open }
      it { @fork_merge_request.notes.should be_empty }
      it { @fork_merge_request.should be_open }
    end

    context 'push to origin repo target branch after fork project was removed' do
      before do
        @fork_project.destroy
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { @merge_request.notes.should be_empty }
      it { @merge_request.should be_merged }
      it { @fork_merge_request.should be_open }
      it { @fork_merge_request.notes.should be_empty }
    end

    def reload_mrs
      @merge_request.reload
      @fork_merge_request.reload
    end
  end
end

require 'spec_helper'

describe Projects::CreateService do
  describe :create_by_user do
    before do
      @user = create :user
      @admin = create :user, admin: true
      @opts = {
        name: "GitLab",
        namespace: @user.namespace
      }
    end

    context 'user namespace' do
      before do
        @project = create_project(@user, @opts)
      end

      it { @project.should be_valid }
      it { @project.owner.should == @user }
      it { @project.namespace.should == @user.namespace }
    end

    context 'group namespace' do
      before do
        @group = create :group
        @group.add_owner(@user)

        @opts.merge!(namespace_id: @group.id)
        @project = create_project(@user, @opts)
      end

      it { @project.should be_valid }
      it { @project.owner.should == @group }
      it { @project.namespace.should == @group }
    end

    context 'wiki_enabled creates repository directory' do
      context 'wiki_enabled true creates wiki repository directory' do
        before do
          @project = create_project(@user, @opts)
          @path = ProjectWiki.new(@project, @user).send(:path_to_repo)
        end

        it { File.exists?(@path).should be_true }
      end

      context 'wiki_enabled false does not create wiki repository directory' do
        before do
          @opts.merge!(wiki_enabled: false)
          @project = create_project(@user, @opts)
          @path = ProjectWiki.new(@project, @user).send(:path_to_repo)
        end

        it { File.exists?(@path).should be_false }
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end

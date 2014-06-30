require 'spec_helper'

describe Projects::UpdateService do
  describe :update_by_user do
    before do
      @user = create :user
      @admin = create :user, admin: true
      @project = create :project, creator_id: @user.id, namespace: @user.namespace
      @opts = {}
    end

    context 'should be private when updated to private' do
      before do
       @created_private = @project.private?

        @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        update_project(@project, @user, @opts)
      end

      it { @created_private.should be_true }
      it { @project.private?.should be_true }
    end

    context 'should be internal when updated to internal' do
      before do
        @created_private = @project.private?

        @opts.merge!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        update_project(@project, @user, @opts)
      end

      it { @created_private.should be_true }
      it { @project.internal?.should be_true }
    end

    context 'should be public when updated to public' do
      before do
        @created_private = @project.private?

        @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        update_project(@project, @user, @opts)
      end

      it { @created_private.should be_true }
      it { @project.public?.should be_true }
    end

    context 'respect configured visibility restrictions setting' do
      before(:each) do
        @restrictions = double("restrictions")
        @restrictions.stub(:restricted_visibility_levels) { [ Gitlab::VisibilityLevel::PUBLIC ] }
        Settings.stub_chain(:gitlab).and_return(@restrictions)
      end

      context 'should be private when updated to private' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          update_project(@project, @user, @opts)
        end

        it { @created_private.should be_true }
        it { @project.private?.should be_true }
      end

      context 'should be internal when updated to internal' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          update_project(@project, @user, @opts)
        end

        it { @created_private.should be_true }
        it { @project.internal?.should be_true }
      end

      context 'should be private when updated to public' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          update_project(@project, @user, @opts)
        end

        it { @created_private.should be_true }
        it { @project.private?.should be_true }
      end

      context 'should be public when updated to public by admin' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          update_project(@project, @admin, @opts)
        end

        it { @created_private.should be_true }
        it { @project.public?.should be_true }
      end
    end
  end

  def update_project(project, user, opts)
    Projects::UpdateService.new(project, user, opts).execute
  end
end

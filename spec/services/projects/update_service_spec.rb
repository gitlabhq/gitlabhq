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

      it { expect(@created_private).to be_truthy }
      it { expect(@project.private?).to be_truthy }
    end

    context 'should be internal when updated to internal' do
      before do
        @created_private = @project.private?

        @opts.merge!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        update_project(@project, @user, @opts)
      end

      it { expect(@created_private).to be_truthy }
      it { expect(@project.internal?).to be_truthy }
    end

    context 'should be public when updated to public' do
      before do
        @created_private = @project.private?

        @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        update_project(@project, @user, @opts)
      end

      it { expect(@created_private).to be_truthy }
      it { expect(@project.public?).to be_truthy }
    end

    context 'respect configured visibility restrictions setting' do
      before(:each) do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'should be private when updated to private' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          update_project(@project, @user, @opts)
        end

        it { expect(@created_private).to be_truthy }
        it { expect(@project.private?).to be_truthy }
      end

      context 'should be internal when updated to internal' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          update_project(@project, @user, @opts)
        end

        it { expect(@created_private).to be_truthy }
        it { expect(@project.internal?).to be_truthy }
      end

      context 'should be private when updated to public' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          update_project(@project, @user, @opts)
        end

        it { expect(@created_private).to be_truthy }
        it { expect(@project.private?).to be_truthy }
      end

      context 'should be public when updated to public by admin' do
        before do
          @created_private = @project.private?

          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          update_project(@project, @admin, @opts)
        end

        it { expect(@created_private).to be_truthy }
        it { expect(@project.public?).to be_truthy }
      end
    end
  end

  def update_project(project, user, opts)
    Projects::UpdateService.new(project, user, opts).execute
  end
end

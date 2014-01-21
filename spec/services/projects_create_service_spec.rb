require 'spec_helper'

describe Projects::CreateService do
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

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

    context 'respect configured visibility setting' do
      before(:each) do
        @settings = double("settings")
        @settings.stub(:issues) { true }
        @settings.stub(:merge_requests) { true }
        @settings.stub(:wiki) { true }
        @settings.stub(:wall) { true }
        @settings.stub(:snippets) { true }
        stub_const("Settings", Class.new)
        @restrictions = double("restrictions")
        @restrictions.stub(:restricted_visibility_levels) { [] }
        Settings.stub_chain(:gitlab).and_return(@restrictions)
        Settings.stub_chain(:gitlab, :default_projects_features).and_return(@settings)
      end

      context 'should be public when setting is public' do
        before do
          @settings.stub(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          @project = create_project(@user, @opts)
        end

        it { @project.public?.should be_true }
      end

      context 'should be private when setting is private' do
        before do
          @settings.stub(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
          @project = create_project(@user, @opts)
        end

        it { @project.private?.should be_true }
      end

      context 'should be internal when setting is internal' do
        before do
          @settings.stub(:visibility_level) { Gitlab::VisibilityLevel::INTERNAL }
          @project = create_project(@user, @opts)
        end

        it { @project.internal?.should be_true }
      end
    end

    context 'respect configured visibility restrictions setting' do
      before(:each) do
        @settings = double("settings")
        @settings.stub(:issues) { true }
        @settings.stub(:merge_requests) { true }
        @settings.stub(:wiki) { true }
        @settings.stub(:wall) { true }
        @settings.stub(:snippets) { true }
        @settings.stub(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
        stub_const("Settings", Class.new)
        @restrictions = double("restrictions")
        @restrictions.stub(:restricted_visibility_levels) { [ Gitlab::VisibilityLevel::PUBLIC ] }
        Settings.stub_chain(:gitlab).and_return(@restrictions)
        Settings.stub_chain(:gitlab, :default_projects_features).and_return(@settings)
      end

      context 'should be private when option is public' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          @project = create_project(@user, @opts)
        end

        it { @project.private?.should be_true }
      end

      context 'should be public when option is public for admin' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          @project = create_project(@admin, @opts)
        end

        it { @project.public?.should be_true }
      end

      context 'should be private when option is private' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          @project = create_project(@user, @opts)
        end

        it { @project.private?.should be_true }
      end

      context 'should be internal when option is internal' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          @project = create_project(@user, @opts)
        end

        it { @project.internal?.should be_true }
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end


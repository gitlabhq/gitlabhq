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

      it { expect(@project).to be_valid }
      it { expect(@project.owner).to eq(@user) }
      it { expect(@project.namespace).to eq(@user.namespace) }
    end

    context 'group namespace' do
      before do
        @group = create :group
        @group.add_owner(@user)

        @opts.merge!(namespace_id: @group.id)
        @project = create_project(@user, @opts)
      end

      it { expect(@project).to be_valid }
      it { expect(@project.owner).to eq(@group) }
      it { expect(@project.namespace).to eq(@group) }
    end

    context 'wiki_enabled creates repository directory' do
      context 'wiki_enabled true creates wiki repository directory' do
        before do
          @project = create_project(@user, @opts)
          @path = ProjectWiki.new(@project, @user).send(:path_to_repo)
        end

        it { expect(File.exists?(@path)).to be_true }
      end

      context 'wiki_enabled false does not create wiki repository directory' do
        before do
          @opts.merge!(wiki_enabled: false)
          @project = create_project(@user, @opts)
          @path = ProjectWiki.new(@project, @user).send(:path_to_repo)
        end

        it { expect(File.exists?(@path)).to be_false }
      end
    end

    context 'respect configured visibility setting' do
      before(:each) do
        @settings = double("settings")
        allow(@settings).to receive(:issues) { true }
        allow(@settings).to receive(:merge_requests) { true }
        allow(@settings).to receive(:wiki) { true }
        allow(@settings).to receive(:snippets) { true }
        Gitlab.config.gitlab.stub(restricted_visibility_levels: [])
        allow(Gitlab.config.gitlab).to receive(:default_projects_features).and_return(@settings)
      end

      context 'should be public when setting is public' do
        before do
          allow(@settings).to receive(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          @project = create_project(@user, @opts)
        end

        it { expect(@project.public?).to be_true }
      end

      context 'should be private when setting is private' do
        before do
          allow(@settings).to receive(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
          @project = create_project(@user, @opts)
        end

        it { expect(@project.private?).to be_true }
      end

      context 'should be internal when setting is internal' do
        before do
          allow(@settings).to receive(:visibility_level) { Gitlab::VisibilityLevel::INTERNAL }
          @project = create_project(@user, @opts)
        end

        it { expect(@project.internal?).to be_true }
      end
    end

    context 'respect configured visibility restrictions setting' do
      before(:each) do
        @settings = double("settings")
        allow(@settings).to receive(:issues) { true }
        allow(@settings).to receive(:merge_requests) { true }
        allow(@settings).to receive(:wiki) { true }
        allow(@settings).to receive(:snippets) { true }
        allow(@settings).to receive(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
        @restrictions = [ Gitlab::VisibilityLevel::PUBLIC ]
        Gitlab.config.gitlab.stub(restricted_visibility_levels: @restrictions)
        allow(Gitlab.config.gitlab).to receive(:default_projects_features).and_return(@settings)
      end

      context 'should be private when option is public' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          @project = create_project(@user, @opts)
        end

        it { expect(@project.private?).to be_true }
      end

      context 'should be public when option is public for admin' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          @project = create_project(@admin, @opts)
        end

        it { expect(@project.public?).to be_true }
      end

      context 'should be private when option is private' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          @project = create_project(@user, @opts)
        end

        it { expect(@project.private?).to be_true }
      end

      context 'should be internal when option is internal' do
        before do
          @opts.merge!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          @project = create_project(@user, @opts)
        end

        it { expect(@project.internal?).to be_true }
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end

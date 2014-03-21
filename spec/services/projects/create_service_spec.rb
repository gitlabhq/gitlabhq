require 'spec_helper'

describe Projects::CreateService do
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

  describe "#execute" do
    let(:project) { create_project }
    let(:opts) { {name: "GitLab", namespace: user.namespace} }

    # NOTE: Must be loaded before we do any of the configuration stubbing in tests below
    let!(:user) { create(:user) }

    context "in a user namespace" do
      it "creates a valid project" do
        project.should be_valid
      end

      it "assigns current user as project owner" do
        project.owner.should == user
      end

      it "assigns owner's namespace to the project" do
        project.namespace.should == user.namespace
      end
    end

    context 'in a group namespace' do
      let(:group) { create(:group, owner: user) }

      before do
        group.add_owner(user)
        opts.merge!(namespace_id: group.id)
      end

      it "creates a valid project" do
        project.should be_valid
      end

      it "assigns group as project owner" do
        project.owner.should == group
      end

      it "assigns group's namespace to the project" do
        project.namespace.should == group
      end
    end

    describe "wiki repository" do
      let(:wiki) { GollumWiki.new(project, user) }

      it "gets created when enabled" do
        wiki.repo_exists?.should be_true
      end

      it "does not get created when disabled" do
        opts.merge!(wiki_enabled: false)

        wiki.repo_exists?.should be_false
      end
    end

    describe "project visibility" do
      let(:settings) { double('settings', {issues: true, merge_requests: true, wiki: true, wall: true, snippets: true}) }

      before do
        stub_const("Settings", Class.new)
      end

      context "with no restricted visibility levels" do
        before do
          Settings.stub_chain(:gitlab).and_return(double("restrictions", {
            restricted_visibility_levels: [],
            default_projects_features: settings
          }))
        end

        it 'should be public when setting is public' do
          settings.stub(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

          project.should be_public
        end

        it 'should be private when setting is private' do
          settings.stub(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }

          project.should be_private
        end

        it 'should be internal when setting is internal' do
          settings.stub(:visibility_level) { Gitlab::VisibilityLevel::INTERNAL }
          project.should be_internal
        end
      end

      context "with restricted visibility levels" do
        before do
          settings.stub(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          Settings.stub_chain(:gitlab).and_return(double("restrictions", {
            restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC],
            default_projects_features: settings
          }))
        end

        it 'is reset to system default when provided level is restricted' do
          opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project.should be_private
        end

        it 'is public when provided level is restricted and user is an admin' do
          opts.merge!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          user.admin = true
          project.should be_public
        end

        it 'is private when not restricted' do
          opts.merge!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          project.should be_private
        end

        it 'is internal when not restricted' do
          opts.merge!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          project.should be_internal
        end
      end
    end

    def create_project
      # user and opts come from our memoized variables
      Projects::CreateService.new(user, opts).execute
    end
  end
end

require 'spec_helper'

describe Project, "Hooks" do
  let(:project) { create(:project) }
  before do
    @key = create(:key, user: project.owner)
    @user = @key.user
    @key_id = @key.identifier
  end

  describe "Post Receive Event" do
    it "should create push event" do
      oldrev, newrev, ref = '00000000000000000000000000000000', 'newrev', 'refs/heads/master'
      data = project.post_receive_data(oldrev, newrev, ref, @user)

      project.observe_push(data)
      event = Event.last

      event.should_not be_nil
      event.project.should == project
      event.action.should == Event::Pushed
      event.data.should == data
    end
  end

  describe "Project hooks" do
    context "with no web hooks" do
      it "raises no errors" do
        lambda {
          project.execute_hooks({})
        }.should_not raise_error
      end
    end

    context "with web hooks" do
      before do
        @project_hook = create(:project_hook)
        @project_hook_2 = create(:project_hook)
        project.hooks << [@project_hook, @project_hook_2]
      end

      it "executes multiple web hook" do
        @project_hook.should_receive(:execute).once
        @project_hook_2.should_receive(:execute).once

        project.trigger_post_receive('oldrev', 'newrev', 'refs/heads/master', @user)
      end
    end

    context "does not execute web hooks" do
      before do
        @project_hook = create(:project_hook)
        project.hooks << [@project_hook]
      end

      it "when pushing a branch for the first time" do
        @project_hook.should_not_receive(:execute)
        project.trigger_post_receive('00000000000000000000000000000000', 'newrev', 'refs/heads/master', @user)
      end

      it "when pushing tags" do
        @project_hook.should_not_receive(:execute)
        project.trigger_post_receive('oldrev', 'newrev', 'refs/tags/v1.0.0', @user)
      end
    end

    context "when pushing new branches" do

    end

    context "when gathering commit data" do
      before do
        @oldrev, @newrev, @ref = project.fresh_commits(2).last.sha, project.fresh_commits(2).first.sha, 'refs/heads/master'
        @commit = project.fresh_commits(2).first

        # Fill nil/empty attributes
        project.description = "This is a description"

        @data = project.post_receive_data(@oldrev, @newrev, @ref, @user)
      end

      subject { @data }

      it { should include(before: @oldrev) }
      it { should include(after: @newrev) }
      it { should include(ref: @ref) }
      it { should include(user_id: project.owner.id) }
      it { should include(user_name: project.owner.name) }

      context "with repository data" do
        subject { @data[:repository] }

        it { should include(name: project.name) }
        it { should include(url: project.url_to_repo) }
        it { should include(description: project.description) }
        it { should include(homepage: project.web_url) }
      end

      context "with commits" do
        subject { @data[:commits] }

        it { should be_an(Array) }
        it { should have(1).element }

        context "the commit" do
          subject { @data[:commits].first }

          it { should include(id: @commit.id) }
          it { should include(message: @commit.safe_message) }
          it { should include(timestamp: @commit.date.xmlschema) }
          it { should include(url: "#{Gitlab.config.gitlab.url}/#{project.code}/commit/#{@commit.id}") }

          context "with a author" do
            subject { @data[:commits].first[:author] }

            it { should include(name: @commit.author_name) }
            it { should include(email: @commit.author_email) }
          end
        end
      end
    end
  end
end

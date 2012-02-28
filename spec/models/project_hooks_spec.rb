require 'spec_helper'

describe Project, "Hooks" do
  let(:project) { Factory :project }

  describe "Post Receive Event" do 
    it "should create push event" do 
      oldrev, newrev, ref = '00000000000000000000000000000000', 'newrev', 'refs/heads/master'
      project.observe_push(oldrev, newrev, ref)
      event = Event.last

      event.should_not be_nil
      event.project.should == project
      event.action.should == Event::Pushed
      event.data == project.web_hook_data(oldrev, newrev, ref)
    end
  end

  describe "Web hooks" do
    context "with no web hooks" do
      it "raises no errors" do
        lambda {
          project.execute_web_hooks('oldrev', 'newrev', 'ref')
        }.should_not raise_error
      end
    end

    context "with web hooks" do
      before do
        @webhook = Factory(:web_hook)
        @webhook_2 = Factory(:web_hook)
        project.web_hooks << [@webhook, @webhook_2]
      end

      it "executes multiple web hook" do
        @webhook.should_receive(:execute).once
        @webhook_2.should_receive(:execute).once

        project.execute_web_hooks('oldrev', 'newrev', 'refs/heads/master')
      end
    end

    context "does not execute web hooks" do
      before do
        @webhook = Factory(:web_hook)
        project.web_hooks << [@webhook]
      end

      it "when pushing a branch for the first time" do
        @webhook.should_not_receive(:execute)
        project.execute_web_hooks('00000000000000000000000000000000', 'newrev', 'refs/heads/master')
      end

      it "when pushing tags" do
        @webhook.should_not_receive(:execute)
        project.execute_web_hooks('oldrev', 'newrev', 'refs/tags/v1.0.0')
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

        @data = project.web_hook_data(@oldrev, @newrev, @ref)
      end

      subject { @data }

      it { should include(before: @oldrev) }
      it { should include(after: @newrev) }
      it { should include(ref: @ref) }

      context "with repository data" do
        subject { @data[:repository] }

        it { should include(name: project.name) }
        it { should include(url: project.web_url) }
        it { should include(description: project.description) }
        it { should include(homepage: project.web_url) }
        it { should include(private: project.private?) }
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
          it { should include(url: "http://localhost/#{project.code}/commits/#{@commit.id}") }

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

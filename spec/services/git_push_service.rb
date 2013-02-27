require 'spec_helper'

describe GitPushService do
  let (:user)          { create :user }
  let (:project)       { create :project }
  let (:service) { GitPushService.new }

  before do
    @oldrev = 'b98a310def241a6fd9c9a9a3e7934c48e498fe81'
    @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
    @ref = 'refs/heads/master'
  end

  describe "Git Push Data" do
    before do
      service.execute(project, user, @oldrev, @newrev, @ref)
      @push_data = service.push_data
      @commit = project.repository.commit(@newrev)
    end

    subject { @push_data }

    it { should include(before: @oldrev) }
    it { should include(after: @newrev) }
    it { should include(ref: @ref) }
    it { should include(user_id: user.id) }
    it { should include(user_name: user.name) }

    context "with repository data" do
      subject { @push_data[:repository] }

      it { should include(name: project.name) }
      it { should include(url: project.url_to_repo) }
      it { should include(description: project.description) }
      it { should include(homepage: project.web_url) }
    end

    context "with commits" do
      subject { @push_data[:commits] }

      it { should be_an(Array) }
      it { should have(1).element }

      context "the commit" do
        subject { @push_data[:commits].first }

        it { should include(id: @commit.id) }
        it { should include(message: @commit.safe_message) }
        it { should include(timestamp: @commit.date.xmlschema) }
        it { should include(url: "#{Gitlab.config.gitlab.url}/#{project.code}/commit/#{@commit.id}") }

        context "with a author" do
          subject { @push_data[:commits].first[:author] }

          it { should include(name: @commit.author_name) }
          it { should include(email: @commit.author_email) }
        end
      end
    end
  end

  describe "Push Event" do
    before do
      service.execute(project, user, @oldrev, @newrev, @ref)
      @event = Event.last
    end

    it { @event.should_not be_nil }
    it { @event.project.should == project }
    it { @event.action.should == Event::PUSHED }
    it { @event.data.should == service.push_data }
  end

  describe "Web Hooks" do
    context "with web hooks" do
      before do
        @project_hook = create(:project_hook)
        @project_hook_2 = create(:project_hook)
        project.hooks << [@project_hook, @project_hook_2]

        stub_request(:post, @project_hook.url)
        stub_request(:post, @project_hook_2.url)
      end

      it "executes multiple web hook" do
        @project_hook.should_receive(:async_execute).once
        @project_hook_2.should_receive(:async_execute).once

        service.execute(project, user, @oldrev, @newrev, @ref)
      end
    end

    context "does not execute web hooks" do
      before do
        @project_hook = create(:project_hook)
        project.hooks << [@project_hook]
      end

      it "when pushing a branch for the first time" do
        @project_hook.should_not_receive(:execute)
        service.execute(project, user, '00000000000000000000000000000000', 'newrev', 'refs/heads/master')
      end

      it "when pushing tags" do
        @project_hook.should_not_receive(:execute)
        service.execute(project, user, 'newrev', 'newrev', 'refs/tags/v1.0.0')
      end
    end
  end
end


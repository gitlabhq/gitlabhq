require 'spec_helper'

describe GitTagPushService do
  let (:user) { create :user }
  let (:project) { create :project }
  let (:service) { GitTagPushService.new }

  before do
    @ref = 'refs/tags/super-tag'
    @oldrev = 'b98a310def241a6fd9c9a9a3e7934c48e498fe81'
    @newrev = 'b19a04f53caeebf4fe5ec2327cb83e9253dc91bb'
  end

  describe 'Git Tag Push Data' do
    before do
      service.execute(project, user, @oldrev, @newrev, @ref)
      @push_data = service.push_data
    end

    subject { @push_data }

    it { should include(ref: @ref) }
    it { should include(before: @oldrev) }
    it { should include(after: @newrev) }
    it { should include(user_id: user.id) }
    it { should include(user_name: user.name) }
    it { should include(project_id: project.id) }

    context 'With repository data' do
      subject { @push_data[:repository] }

      it { should include(name: project.name) }
      it { should include(url: project.url_to_repo) }
      it { should include(description: project.description) }
      it { should include(homepage: project.web_url) }
    end
  end

  describe "Web Hooks" do
    context "execute web hooks" do
      it "when pushing tags" do
        project.should_receive(:execute_hooks)
        service.execute(project, user, 'oldrev', 'newrev', 'refs/tags/v1.0.0')
      end
    end
  end
end

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

    it { is_expected.to include(ref: @ref) }
    it { is_expected.to include(before: @oldrev) }
    it { is_expected.to include(after: @newrev) }
    it { is_expected.to include(user_id: user.id) }
    it { is_expected.to include(user_name: user.name) }
    it { is_expected.to include(project_id: project.id) }

    context 'With repository data' do
      subject { @push_data[:repository] }

      it { is_expected.to include(name: project.name) }
      it { is_expected.to include(url: project.url_to_repo) }
      it { is_expected.to include(description: project.description) }
      it { is_expected.to include(homepage: project.web_url) }
    end
  end

  describe "Web Hooks" do
    context "execute web hooks" do
      it "when pushing tags" do
        expect(project).to receive(:execute_hooks)
        service.execute(project, user, 'oldrev', 'newrev', 'refs/tags/v1.0.0')
      end
    end
  end
end

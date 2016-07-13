require 'spec_helper'

describe TestHookService, services: true do
  let(:user)         { create :user }
  let(:group)        { create :group }
  let(:project)      { create :project, group: group }
  let(:project_hook) { create :project_hook, project: project }
  let(:group_hook)   { create :group_hook, group: group }

  describe '#execute' do
    it "should successfully execute the project hook" do
      stub_request(:post, project_hook.url).to_return(status: 200)
      expect(TestHookService.new.execute(project_hook, user)).to be_truthy
    end

    it "should successfully execute the group hook" do
      project.reload
      stub_request(:post, group_hook.url).to_return(status: 200)
      expect(TestHookService.new.execute(group_hook, user)).to be_truthy
    end
  end
end

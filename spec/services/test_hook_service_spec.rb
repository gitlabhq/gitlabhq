require 'spec_helper'

describe TestHookService do
  let (:user)    { create :user }
  let (:project) { create :project }
  let (:hook)    { create :project_hook, project: project }

  describe :execute do
    it "should execute successfully" do
      stub_request(:post, hook.url).to_return(status: 200)
      TestHookService.new.execute(hook, user).should be_true
    end
  end
end

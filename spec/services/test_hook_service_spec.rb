require 'spec_helper'

describe Hooks::Test do
  let (:user)    { create :user }
  let (:project) { create :project }
  let (:hook)    { create :project_hook, project: project }

  describe :execute do
    it "should execute successfully" do
      stub_request(:post, hook.url).to_return(status: 200)
      result = Hooks::Test.perform(hook: hook, user: user)
      result.should be_success
    end
  end
end

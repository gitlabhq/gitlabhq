require "spec_helper"

describe Subscribable, "Subscribable" do
  let(:resource) { create(:issue) }
  let(:user) { create(:user) }

  describe "#subscribed?" do
    it do
      expect(resource.subscribed?(user)).to be_falsey
      resource.toggle_subscription(user)
      expect(resource.subscribed?(user)).to be_truthy
      resource.toggle_subscription(user)
      expect(resource.subscribed?(user)).to be_falsey
    end
  end
end

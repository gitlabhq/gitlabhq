
require 'spec_helper'

describe ForkRegistrationWorker do
  context "as a resque worker" do
    it "reponds to #perform" do
      expect(ForkRegistrationWorker.new).to respond_to(:perform)
    end
  end
end

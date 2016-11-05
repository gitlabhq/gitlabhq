require 'spec_helper'

describe UserContributionWorker do
  describe "#perform" do
    it "calls the calculation of user contributions for the given date" do
      worker = described_class.new
      date = 1.day.ago

      expect(UserContribution).to receive(:calculate_for).with(date)
      worker.perform(date)
    end
  end
end

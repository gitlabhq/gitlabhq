require 'spec_helper'

describe ChatNotificationService, models: true do
  describe "Associations" do
    before do
      allow(subject).to receive(:activated?).and_return(true)
    end

    it { is_expected.to validate_presence_of :webhook }
  end
end

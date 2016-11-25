require 'spec_helper'

describe ChatService, models: true do
  describe "Associations" do
    before { allow(subject).to receive(:activated?).and_return(true) }
    it { is_expected.to validate_presence_of :webhook }
  end
end

# frozen_string_literal: true
require "spec_helper"

RSpec.describe PagesUpdateConfigurationWorker do
  let_it_be(:project) { create(:project) }

  describe "#perform" do
    it "does not break" do
      expect { subject.perform(-1) }.not_to raise_error
    end
  end
end

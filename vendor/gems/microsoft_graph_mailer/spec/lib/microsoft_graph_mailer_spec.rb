# frozen_string_literal: true

require "spec_helper"

RSpec.describe MicrosoftGraphMailer do
  describe "::VERSION" do
    it "returns a version number" do
      expect(MicrosoftGraphMailer::VERSION).to  eq("0.1.0")
    end
  end

  describe "::Error" do
    it "its superclass is StandardError" do
      expect(MicrosoftGraphMailer::Error.superclass).to eq(StandardError)
    end
  end

  describe "::ConfigurationError" do
    it "its superclass is MicrosoftGraphMailer::Error" do
      expect(MicrosoftGraphMailer::ConfigurationError.superclass).to eq(MicrosoftGraphMailer::Error)
    end
  end

  describe "::DeliveryError" do
    it "its superclass is MicrosoftGraphMailer::Error" do
      expect(MicrosoftGraphMailer::DeliveryError.superclass).to eq(MicrosoftGraphMailer::Error)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::Pumble, feature_category: :integrations do
  it_behaves_like Integrations::HasAvatar

  it_behaves_like "chat integration", "Pumble" do
    let(:client_arguments) { webhook_url }
    let(:payload) do
      {
        text: be_present
      }
    end
  end
end

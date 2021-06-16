# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::WebexTeams do
  it_behaves_like "chat integration", "Webex Teams" do
    let(:client_arguments) { webhook_url }
    let(:payload) do
      {
        markdown: be_present
      }
    end
  end
end

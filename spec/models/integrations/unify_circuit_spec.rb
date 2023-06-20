# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::UnifyCircuit, feature_category: :integrations do
  it_behaves_like "chat integration", "Unify Circuit" do
    let(:client_arguments) { webhook_url }
    let(:payload) do
      {
        subject: project.full_name,
        text: be_present,
        markdown: true
      }
    end
  end
end

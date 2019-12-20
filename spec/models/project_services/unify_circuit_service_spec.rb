# frozen_string_literal: true

require "spec_helper"

describe UnifyCircuitService do
  it_behaves_like "chat service", "Unify Circuit" do
    let(:client_arguments) { webhook_url }
    let(:content_key) { :subject }
  end
end

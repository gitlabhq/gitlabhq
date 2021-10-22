# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Metrics::RailsSlis do
  # Limit what routes we'll initialize so we don't have to load the entire thing
  before do
    api_route = API::API.routes.find do |route|
      API::Base.endpoint_id_for_route(route) == "GET /api/:version/version"
    end

    allow(Gitlab::RequestEndpoints).to receive(:all_api_endpoints).and_return([api_route])
    allow(Gitlab::RequestEndpoints).to receive(:all_controller_actions).and_return([[ProjectsController, 'show']])
  end

  describe '.initialize_request_slis_if_needed!' do
    it "initializes the SLI for all possible endpoints if they weren't" do
      possible_labels = [
        {
          endpoint_id: "GET /api/:version/version",
          feature_category: :not_owned,
          request_urgency: :default
        },
        {
          endpoint_id: "ProjectsController#show",
          feature_category: :projects,
          request_urgency: :default
        }
      ]

      expect(Gitlab::Metrics::Sli).to receive(:initialized?).with(:rails_request_apdex) { false }
      expect(Gitlab::Metrics::Sli).to receive(:initialize_sli).with(:rails_request_apdex, array_including(*possible_labels)).and_call_original

      described_class.initialize_request_slis_if_needed!
    end

    it 'does not initialize the SLI if they were initialized already' do
      expect(Gitlab::Metrics::Sli).to receive(:initialized?).with(:rails_request_apdex) { true }
      expect(Gitlab::Metrics::Sli).not_to receive(:initialize_sli)

      described_class.initialize_request_slis_if_needed!
    end
  end

  describe '.request_apdex' do
    it 'returns the initialized request apdex SLI object' do
      described_class.initialize_request_slis_if_needed!

      expect(described_class.request_apdex).to be_initialized
    end
  end
end

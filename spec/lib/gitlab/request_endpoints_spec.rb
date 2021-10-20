# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::RequestEndpoints do
  describe '.all_api_endpoints' do
    it 'selects all feature API classes' do
      api_classes = described_class.all_api_endpoints.map { |route| route.app.options[:for] }

      expect(api_classes).to all(include(Gitlab::EndpointAttributes))
    end
  end

  describe '.all_controller_actions' do
    it 'selects all feature controllers and action names' do
      all_controller_actions = described_class.all_controller_actions
      controller_classes = all_controller_actions.map(&:first)
      all_actions = all_controller_actions.map(&:last)

      expect(controller_classes).to all(include(Gitlab::EndpointAttributes))
      expect(controller_classes).not_to include(ApplicationController, Devise::UnlocksController)
      expect(all_actions).to all(be_a(String))
    end
  end
end

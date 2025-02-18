# frozen_string_literal: true

require 'view_component/test_helpers'

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  config.include Devise::Test::ControllerHelpers, type: :component

  config.before(:each, type: :component) do
    @request = vc_test_controller.request
  end

  config.include_context 'when page has no HTML escapes', type: :component
end

# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :channel) do
    stub_action_cable_connection
  end
end

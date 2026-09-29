# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'telemetry_endpoint initializer', feature_category: :service_ping do
  subject(:load_initializer) { load Rails.root.join('config/initializers/telemetry_endpoint.rb') }

  it 'logs the telemetry configuration at boot' do
    expect(Gitlab::TelemetryEndpoint).to receive(:log_configuration)

    load_initializer
  end
end

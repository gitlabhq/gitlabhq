# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::SecureHeaders, feature_category: :shared do
  let(:status_origin) { 200 }
  let(:body_origin) { ['Hello, World'] }
  let(:app) { ->(_env) { [status_origin, {}, body_origin] } }
  let(:env) { Rack::MockRequest.env_for('/', method: 'get') }

  subject(:middleware) { described_class.new(app) }

  it 'adds the expected header to the response and preserves the original response status and body' do
    status, headers, body = middleware.call(env)

    expect(headers['NEL']).to eq('{"max_age": 0}')
    expect(status).to eq(status_origin)
    expect(body).to eq(body_origin)
  end
end

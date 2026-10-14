# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Testing::RequestBlockerMiddleware, feature_category: :tooling do
  let(:app_body) { instance_double(Rack::BodyProxy, close: nil) }
  let(:app) { ->(_env) { [200, {}, app_body] } }
  let(:env) { Rack::MockRequest.env_for('/') }

  subject(:middleware) { described_class.new(app) }

  after do
    described_class.allow_requests!
  end

  it 'counts the request as active until the response body is closed' do
    _status, _headers, body = middleware.call(env)

    expect(described_class.num_active_requests).to eq(1)

    body.close

    expect(app_body).to have_received(:close)
    expect(described_class.num_active_requests).to eq(0)
  end

  it 'decrements only once when the body is closed more than once' do
    _status, _headers, body = middleware.call(env)

    2.times { body.close }

    expect(described_class.num_active_requests).to eq(0)
  end

  context 'when requests are blocked' do
    before do
      described_class.block_requests!
    end

    it 'responds with 503 and stops counting once the body is closed' do
      status, _headers, body = middleware.call(env)

      expect(status).to eq(503)

      body.close

      expect(described_class.num_active_requests).to eq(0)
    end
  end

  context 'when the app raises' do
    let(:app) { ->(_env) { raise ArgumentError } }

    it 'stops counting the request' do
      expect { middleware.call(env) }.to raise_error(ArgumentError)

      expect(described_class.num_active_requests).to eq(0)
    end
  end

  context 'when used through Rack::MockRequest' do
    let(:app_body) { ['OK'] }

    it 'stops counting the request once the response is read' do
      Rack::MockRequest.new(middleware).get('/')

      expect(described_class.num_active_requests).to eq(0)
    end
  end
end

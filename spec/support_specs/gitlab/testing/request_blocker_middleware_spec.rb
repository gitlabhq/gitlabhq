# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Testing::RequestBlockerMiddleware, feature_category: :tooling do
  let(:app_body) { instance_double(Rack::BodyProxy, close: nil) }
  let(:app) { ->(_env) { [200, {}, app_body] } }
  let(:env) { Rack::MockRequest.env_for('/') }
  let(:bodies) { [] }

  subject(:middleware) { described_class.new(app) }

  # The counter is shared by the whole process. A body left open by a failed
  # example would make every later wait for requests time out, so close them all.
  after do
    bodies.each(&:close)
    described_class.allow_requests!
  end

  def call_middleware
    middleware.call(env).tap { |_status, _headers, body| bodies << body }
  end

  def active_requests
    described_class.num_active_requests
  end

  it 'counts the request as active until the response body is closed' do
    body = nil

    expect { body = call_middleware.last }.to change { active_requests }.by(1)
    expect { body.close }.to change { active_requests }.by(-1)
    expect(app_body).to have_received(:close)
  end

  it 'decrements only once when the body is closed more than once' do
    expect do
      body = call_middleware.last
      2.times { body.close }
    end.not_to change { active_requests }
  end

  context 'when requests are blocked' do
    before do
      described_class.block_requests!
    end

    it 'responds with 503 and stops counting once the body is closed' do
      status = nil

      expect do
        status, _headers, body = call_middleware
        body.close
      end.not_to change { active_requests }

      expect(status).to eq(503)
    end
  end

  context 'when the app raises' do
    let(:app) { ->(_env) { raise ArgumentError } }

    it 'stops counting the request' do
      expect { call_middleware }.to raise_error(ArgumentError).and not_change { active_requests }
    end
  end

  context 'when used through Rack::MockRequest' do
    let(:app_body) { ['OK'] }

    it 'stops counting the request once the response is read' do
      expect { Rack::MockRequest.new(middleware).get('/') }.not_to change { active_requests }
    end
  end
end

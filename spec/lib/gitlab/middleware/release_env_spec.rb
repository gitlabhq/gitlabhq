# frozen_string_literal: true

require 'fast_spec_helper'
require 'rack'

RSpec.describe Gitlab::Middleware::ReleaseEnv, feature_category: :shared do
  let(:body) { double(:body, close: nil) }
  let(:inner_app) { double(:app, call: [200, {}, body]) }
  let(:app) { described_class.new(inner_app) }
  let(:env) { { 'action_controller.instance' => 'something' } }

  describe '#call' do
    it 'keeps the env until the response body is closed', :aggregate_failures do
      status, headers, response_body = app.call(env)

      expect(status).to eq(200)
      expect(headers).to eq({})
      expect(env).not_to be_empty

      response_body.close

      expect(body).to have_received(:close)
      expect(env).to be_empty
    end
  end
end

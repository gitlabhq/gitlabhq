# frozen_string_literal: true

require 'fast_spec_helper'
require 'action_dispatch'
require 'rack'
require 'gitlab/safe_request_store'

RSpec.describe Gitlab::Middleware::WebhookRecursionDetection do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for("/").merge(headers) }

  around do |example|
    Gitlab::SafeRequestStore.ensure_request_store { example.run }
  end

  describe '#call' do
    subject(:call) { described_class.new(app).call(env) }

    context 'when the recursion detection header is present' do
      let(:new_uuid) { SecureRandom.uuid }
      let(:headers) { { 'HTTP_X_GITLAB_EVENT_UUID' => new_uuid } }

      it 'sets the request UUID from the header' do
        expect(app).to receive(:call)
        expect { call }.to change { Gitlab::WebHooks::RecursionDetection::UUID.instance.request_uuid }.to(new_uuid)
      end
    end

    context 'when recursion headers are not present' do
      let(:headers) { {} }

      it 'works without errors' do
        expect(app).to receive(:call)

        call

        expect(Gitlab::WebHooks::RecursionDetection::UUID.instance.request_uuid).to be_nil
      end
    end
  end
end

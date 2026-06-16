# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/safe_request_store'

RSpec.describe Gitlab::Middleware::DuoWorkflowId, feature_category: :duo_agent_platform do
  let(:app) { ->(_env) { [200, {}, ['OK']] } }
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    context 'when X-Gitlab-Duo-Workflow-Id header is present' do
      let(:workflow_id) { 'test-workflow-123' }
      let(:env) { { 'HTTP_X_GITLAB_DUO_WORKFLOW_ID' => workflow_id } }

      it 'stores the workflow ID in SafeRequestStore' do
        Gitlab::SafeRequestStore.ensure_request_store do
          middleware.call(env)

          expect(Gitlab::SafeRequestStore[described_class::STORE_KEY]).to eq(workflow_id)
        end
      end

      it 'calls the app' do
        expect(app).to receive(:call).with(env).and_call_original

        Gitlab::SafeRequestStore.ensure_request_store { middleware.call(env) }
      end
    end

    context 'when X-Gitlab-Duo-Workflow-Id header is absent' do
      let(:env) { {} }

      it 'does not set anything in SafeRequestStore' do
        Gitlab::SafeRequestStore.ensure_request_store do
          middleware.call(env)

          expect(Gitlab::SafeRequestStore[described_class::STORE_KEY]).to be_nil
        end
      end

      it 'calls the app' do
        expect(app).to receive(:call).with(env).and_call_original

        Gitlab::SafeRequestStore.ensure_request_store { middleware.call(env) }
      end
    end

    context 'when X-Gitlab-Duo-Workflow-Id header is blank' do
      let(:env) { { 'HTTP_X_GITLAB_DUO_WORKFLOW_ID' => '' } }

      it 'does not set anything in SafeRequestStore' do
        Gitlab::SafeRequestStore.ensure_request_store do
          middleware.call(env)

          expect(Gitlab::SafeRequestStore[described_class::STORE_KEY]).to be_nil
        end
      end
    end

    context 'when X-Gitlab-Duo-Workflow-Id header exceeds the max length' do
      let(:env) { { 'HTTP_X_GITLAB_DUO_WORKFLOW_ID' => 'a' * 300 } }

      it 'truncates the value to MAX_VALUE_LENGTH characters' do
        Gitlab::SafeRequestStore.ensure_request_store do
          middleware.call(env)

          expect(Gitlab::SafeRequestStore[described_class::STORE_KEY].length).to eq(described_class::MAX_VALUE_LENGTH)
        end
      end
    end
  end
end

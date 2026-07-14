# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::DuoWorkflowId, feature_category: :duo_agent_platform do
  let(:app) { ->(_env) { [200, {}, ['OK']] } }
  let(:middleware) { described_class.new(app) }

  def captured_context_during_app_call(env)
    captured = nil
    inner_app = ->(_env) do
      captured = Gitlab::ApplicationContext.current_context_attribute(:duo_workflow_id)
      [200, {}, ['OK']]
    end
    described_class.new(inner_app).call(env)
    captured
  end

  describe '#call' do
    context 'when X-Gitlab-Duo-Workflow-Id header is present' do
      let(:workflow_id) { 'test-workflow-123' }
      let(:env) { { 'HTTP_X_GITLAB_DUO_WORKFLOW_ID' => workflow_id } }

      it 'pushes the workflow ID into ApplicationContext for the duration of the request' do
        expect(captured_context_during_app_call(env)).to eq(workflow_id)
      end

      it 'does not leak the context outside the request' do
        middleware.call(env)

        expect(Gitlab::ApplicationContext.current_context_attribute(:duo_workflow_id)).to be_nil
      end

      it 'calls the app' do
        expect(app).to receive(:call).with(env).and_call_original

        middleware.call(env)
      end
    end

    context 'when X-Gitlab-Duo-Workflow-Id header is absent' do
      let(:env) { {} }

      it 'does not set duo_workflow_id in ApplicationContext' do
        expect(captured_context_during_app_call(env)).to be_nil
      end

      it 'calls the app' do
        expect(app).to receive(:call).with(env).and_call_original

        middleware.call(env)
      end
    end

    context 'when X-Gitlab-Duo-Workflow-Id header is blank' do
      let(:env) { { 'HTTP_X_GITLAB_DUO_WORKFLOW_ID' => '' } }

      it 'does not set duo_workflow_id in ApplicationContext' do
        expect(captured_context_during_app_call(env)).to be_nil
      end
    end

    context 'when X-Gitlab-Duo-Workflow-Id header exceeds the max length' do
      let(:env) { { 'HTTP_X_GITLAB_DUO_WORKFLOW_ID' => 'a' * 300 } }

      it 'truncates the value to MAX_VALUE_LENGTH characters' do
        expect(captured_context_during_app_call(env).length).to eq(described_class::MAX_VALUE_LENGTH)
      end
    end
  end
end

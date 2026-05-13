# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::DuoApiAuthenticator, feature_category: :api do
  let(:request) do
    instance_double(ActionDispatch::Request, path: '/api/v4/ai/duo_workflows/workflows/123', env: env)
  end

  let(:env) do
    {
      'REQUEST_METHOD' => 'POST',
      'PATH_INFO' => '/api/v4/ai/duo_workflows/workflows/123',
      'CONTENT_TYPE' => 'application/json',
      'rack.input' => StringIO.new('{}')
    }
  end

  describe '.verify!' do
    it 'creates instance and calls verify!' do
      authenticator_instance = instance_double(described_class)
      expect(described_class).to receive(:new).with(request).and_return(authenticator_instance)
      expect(authenticator_instance).to receive(:verify!).and_return(true)

      result = described_class.verify!(request)
      expect(result).to be_truthy
    end

    it 'returns false when verify! returns false' do
      authenticator_instance = instance_double(described_class)
      expect(described_class).to receive(:new).with(request).and_return(authenticator_instance)
      expect(authenticator_instance).to receive(:verify!).and_return(false)

      result = described_class.verify!(request)
      expect(result).to be_falsey
    end
  end

  describe '#initialize' do
    it 'wraps request.env in ActionDispatch::Request' do
      authenticator = described_class.new(request)
      current_request = authenticator.instance_variable_get(:@current_request)

      expect(current_request).to be_a(ActionDispatch::Request)
    end

    it 'preserves request environment' do
      authenticator = described_class.new(request)
      current_request = authenticator.instance_variable_get(:@current_request)

      expect(current_request.env).to eq(env)
    end
  end

  describe '#verify!' do
    subject(:authenticator) { described_class.new(request) }

    context 'when user is found from deploy token' do
      let(:deploy_token) { instance_double(DeployToken) }

      it 'returns true' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: deploy_token,
          find_user_from_bearer_token: nil,
          find_user_from_job_token: nil
        )

        expect(authenticator.verify!).to be_truthy
      end
    end

    context 'when user is found from bearer token' do
      let(:user) { instance_double(User) }

      it 'returns true' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: nil,
          find_user_from_bearer_token: user,
          find_user_from_job_token: nil
        )

        expect(authenticator.verify!).to be_truthy
      end
    end

    context 'when user is found from job token' do
      let(:user) { instance_double(User) }

      it 'returns true' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: nil,
          find_user_from_bearer_token: nil,
          find_user_from_job_token: user
        )

        expect(authenticator.verify!).to be_truthy
      end
    end

    context 'when no user is found from any source' do
      it 'returns false' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: nil,
          find_user_from_bearer_token: nil,
          find_user_from_job_token: nil
        )

        expect(authenticator.verify!).to be_falsey
      end
    end

    context 'when deploy token is found (short-circuit)' do
      let(:deploy_token) { instance_double(DeployToken) }

      it 'does not attempt other authentication methods' do
        allow(authenticator).to receive(:deploy_token_from_request).and_return(deploy_token)
        expect(authenticator).not_to receive(:find_user_from_bearer_token)

        expect(authenticator.verify!).to be_truthy
      end
    end

    context 'when bearer token is found (short-circuit)' do
      let(:user) { instance_double(User) }

      it 'does not attempt job token' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: nil,
          find_user_from_bearer_token: user
        )
        expect(authenticator).not_to receive(:find_user_from_job_token)

        expect(authenticator.verify!).to be_truthy
      end
    end

    context 'when Gitlab::Auth::AuthenticationError is raised' do
      it 'logs error and returns false' do
        allow(authenticator).to receive(:deploy_token_from_request).and_raise(
          Gitlab::Auth::AuthenticationError.new('Invalid token')
        )

        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Duo Workflow API authentication failed',
            error: 'Gitlab::Auth::AuthenticationError'
          )
        )

        expect(authenticator.verify!).to be_falsey
      end
    end

    context 'when StandardError is raised' do
      it 'logs error and returns false' do
        allow(authenticator).to receive(:deploy_token_from_request).and_raise(
          StandardError.new('Unexpected error')
        )

        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Duo Workflow API authentication failed',
            error: 'StandardError'
          )
        )

        expect(authenticator.verify!).to be_falsey
      end
    end

    context 'when error occurs during bearer token lookup' do
      it 'logs the error and returns false' do
        allow(authenticator).to receive(:deploy_token_from_request).and_return(nil)
        allow(authenticator).to receive(:find_user_from_bearer_token).and_raise(
          StandardError.new('Bearer token error')
        )

        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(message: 'Duo Workflow API authentication failed')
        )

        expect(authenticator.verify!).to be_falsey
      end
    end

    context 'when error occurs during job token lookup' do
      it 'logs the error and returns false' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: nil,
          find_user_from_bearer_token: nil
        )
        allow(authenticator).to receive(:find_user_from_job_token).and_raise(
          StandardError.new('Job token error')
        )

        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(message: 'Duo Workflow API authentication failed')
        )

        expect(authenticator.verify!).to be_falsey
      end
    end
  end

  describe '#route_authentication_setting' do
    subject(:authenticator) { described_class.new(request) }

    it 'returns DUO_WORKFLOW_AUTH_SETTING' do
      expect(authenticator.send(:route_authentication_setting)).to eq(
        {
          job_token_allowed: true,
          deploy_token_allowed: true
        }
      )
    end

    it 'allows job token authentication' do
      setting = authenticator.send(:route_authentication_setting)
      expect(setting[:job_token_allowed]).to be_truthy
    end

    it 'allows deploy token authentication' do
      setting = authenticator.send(:route_authentication_setting)
      expect(setting[:deploy_token_allowed]).to be_truthy
    end
  end

  describe '#find_user_from_sources' do
    subject(:authenticator) { described_class.new(request) }

    describe 'authentication method order' do
      let(:deploy_token) { instance_double(DeployToken) }
      let(:user) { instance_double(User) }

      it 'checks deploy_token_from_request first' do
        call_order = []

        allow(authenticator).to receive(:deploy_token_from_request) do
          call_order << :deploy_token
          nil
        end
        allow(authenticator).to receive(:find_user_from_bearer_token) do
          call_order << :bearer_token
          nil
        end
        allow(authenticator).to receive(:find_user_from_job_token) do
          call_order << :job_token
          nil
        end

        authenticator.send(:find_user_from_sources)

        expect(call_order).to eq(%i[deploy_token bearer_token job_token])
      end

      it 'returns deploy token immediately if found' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: deploy_token,
          find_user_from_bearer_token: user
        )

        result = authenticator.send(:find_user_from_sources)

        expect(result).to eq(deploy_token)
      end

      it 'returns bearer token if deploy token not found' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: nil,
          find_user_from_bearer_token: user,
          find_user_from_job_token: user
        )

        result = authenticator.send(:find_user_from_sources)

        expect(result).to eq(user)
      end

      it 'returns job token if deploy and bearer tokens not found' do
        allow(authenticator).to receive_messages(
          deploy_token_from_request: nil,
          find_user_from_bearer_token: nil,
          find_user_from_job_token: user
        )

        result = authenticator.send(:find_user_from_sources)

        expect(result).to eq(user)
      end
    end
  end

  describe 'ActionDispatch::Request wrapping' do
    it 'provides access to request methods' do
      authenticator = described_class.new(request)
      current_request = authenticator.instance_variable_get(:@current_request)

      expect(current_request.path).to eq('/api/v4/ai/duo_workflows/workflows/123')
      expect(current_request.request_method).to eq('POST')
    end

    it 'preserves POST method' do
      authenticator = described_class.new(request)
      current_request = authenticator.instance_variable_get(:@current_request)

      expect(current_request.post?).to be_truthy
    end

    it 'preserves headers from env' do
      env_with_auth = env.merge('HTTP_AUTHORIZATION' => 'Bearer token123')
      request_with_auth = instance_double(ActionDispatch::Request, path: '/api/v4/ai/duo_workflows/workflows/123',
        env: env_with_auth)

      authenticator = described_class.new(request_with_auth)
      current_request = authenticator.instance_variable_get(:@current_request)

      expect(current_request.headers['Authorization']).to eq('Bearer token123')
    end
  end

  describe 'integration with JsonValidation middleware' do
    context 'when called from middleware' do
      let(:user) { create(:user) }

      context 'with valid authentication' do
        it 'allows the request to proceed' do
          authenticator = described_class.new(request)
          allow(authenticator).to receive(:find_user_from_sources).and_return(user)

          expect(authenticator.verify!).to be_truthy
        end
      end

      context 'with invalid authentication' do
        it 'blocks the request' do
          authenticator = described_class.new(request)
          allow(authenticator).to receive(:find_user_from_sources).and_return(nil)

          expect(authenticator.verify!).to be_falsey
        end
      end
    end
  end

  describe 'error logging' do
    subject(:authenticator) { described_class.new(request) }

    it 'includes path in error log' do
      allow(authenticator).to receive(:deploy_token_from_request).and_raise(StandardError)

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(path: '/api/v4/ai/duo_workflows/workflows/123')
      )

      authenticator.verify!
    end

    it 'includes error class name in log' do
      error = RuntimeError.new('Custom error')
      allow(authenticator).to receive(:deploy_token_from_request).and_raise(error)

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(error: 'RuntimeError')
      )

      authenticator.verify!
    end

    it 'includes standard message in log' do
      allow(authenticator).to receive(:deploy_token_from_request).and_raise(StandardError)

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(message: 'Duo Workflow API authentication failed')
      )

      authenticator.verify!
    end
  end

  describe 'included AuthFinders module' do
    subject(:authenticator) { described_class.new(request) }

    it 'includes Gitlab::Auth::AuthFinders' do
      expect(authenticator).to be_a(Gitlab::Auth::AuthFinders)
    end

    it 'responds to auth finder methods' do
      expect(authenticator).to respond_to(:deploy_token_from_request)
      expect(authenticator).to respond_to(:find_user_from_bearer_token)
      expect(authenticator).to respond_to(:find_user_from_job_token)
    end
  end

  describe 'class constant' do
    it 'defines DUO_WORKFLOW_AUTH_SETTING' do
      expect(described_class::DUO_WORKFLOW_AUTH_SETTING).to eq(
        job_token_allowed: true,
        deploy_token_allowed: true
      )
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::RunnerControllerHelpers, feature_category: :continuous_integration do
  include Rack::Test::Methods

  let_it_be(:runner_controller) { create(:ci_runner_controller) }
  let_it_be(:runner_controller_token) { create(:ci_runner_controller_token, runner_controller: runner_controller) }

  let(:api_class) do
    Class.new(API::Base) do
      include API::APIGuard
      helpers API::Helpers
      helpers API::Helpers::RunnerControllerHelpers

      before do
        check_runner_controller_token!
      end

      route_setting :authentication, runner_controller_token_allowed: true

      get '/test' do
        { runner_controller_id: runner_controller.id }.to_json
      end
    end
  end

  def app
    api_class
  end

  describe '#runner_controller' do
    let(:helper_instance) do
      Class.new do
        include API::Helpers::RunnerControllerHelpers

        attr_accessor :token_value

        def runner_controller_token
          token_value
        end
      end.new
    end

    context 'when runner_controller_token is present' do
      it 'returns the associated runner controller' do
        helper_instance.token_value = runner_controller_token

        expect(helper_instance.runner_controller).to eq(runner_controller)
      end
    end

    context 'when runner_controller_token is nil' do
      it 'returns nil' do
        helper_instance.token_value = nil

        expect(helper_instance.runner_controller).to be_nil
      end
    end
  end

  describe '#runner_controller_token' do
    let(:helper_instance) do
      Class.new do
        include API::Helpers::RunnerControllerHelpers
        include Gitlab::Auth::AuthFinders

        attr_accessor :auth_token

        def runner_controller_token_from_authorization_token
          auth_token
        end
      end.new
    end

    context 'when runner_controller_token_from_authorization_token returns a token' do
      it 'returns the token' do
        helper_instance.auth_token = runner_controller_token

        expect(helper_instance.runner_controller_token).to eq(runner_controller_token)
      end

      it 'memoizes the result' do
        helper_instance.auth_token = runner_controller_token

        # Call twice to verify memoization
        first_call = helper_instance.runner_controller_token
        second_call = helper_instance.runner_controller_token

        expect(first_call).to eq(second_call)
        expect(first_call.object_id).to eq(second_call.object_id)
      end
    end

    context 'when runner_controller_token_from_authorization_token returns nil' do
      it 'returns nil' do
        helper_instance.auth_token = nil

        expect(helper_instance.runner_controller_token).to be_nil
      end
    end
  end

  describe '#check_runner_controller_token!' do
    context 'when runner_controller_token is present' do
      before do
        header Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER, runner_controller_token.token
      end

      it 'successfully allows the request and includes runner controller in response' do
        get '/test'

        expect(last_response.status).to eq(200)
        response_body = Gitlab::Json.parse(last_response.body)
        expect(response_body['runner_controller_id']).to eq(runner_controller.id)
      end
    end

    context 'when runner_controller_token is not present' do
      it 'returns unauthorized' do
        get '/test'

        expect(last_response.status).to eq(401)
      end
    end

    context 'when runner_controller_token is invalid' do
      before do
        header Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER, 'glrct-invalid-token'
      end

      it 'returns unauthorized' do
        get '/test'

        expect(last_response.status).to eq(401)
      end
    end

    context 'when runner_controller_token is from a different runner controller' do
      let_it_be(:other_runner_controller) { create(:ci_runner_controller) }
      let_it_be(:other_token) { create(:ci_runner_controller_token, runner_controller: other_runner_controller) }

      before do
        header Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER, other_token.token
      end

      it 'allows the request with the correct runner controller' do
        get '/test'

        expect(last_response.status).to eq(200)
        # The endpoint returns the runner_controller from the token, not a hardcoded one
        # This test verifies that authentication works for any valid token
      end
    end
  end

  describe 'integration with AuthFinders' do
    let(:helper_instance) do
      Class.new do
        include API::Helpers::RunnerControllerHelpers
        include Gitlab::Auth::AuthFinders

        attr_accessor :current_token, :mock_request, :mock_route_setting

        def current_request
          @mock_request
        end

        def route_authentication_setting
          @mock_route_setting || {}
        end
      end.new
    end

    describe '#runner_controller_token_from_authorization_token' do
      let(:request) { instance_double(ActionDispatch::Request, headers: headers, env: {}) }
      let(:headers) { {} }

      before do
        helper_instance.mock_request = request
      end

      context 'when route allows runner_controller_token' do
        before do
          helper_instance.mock_route_setting = { runner_controller_token_allowed: true }
        end

        context 'when valid token is provided in header' do
          let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => runner_controller_token.token } }

          it 'returns the runner controller token' do
            result = helper_instance.runner_controller_token_from_authorization_token

            expect(result).to eq(runner_controller_token)
          end

          it 'sets current_token' do
            helper_instance.runner_controller_token_from_authorization_token

            expect(helper_instance.current_token).to eq(runner_controller_token.token)
          end
        end

        context 'when invalid token is provided' do
          let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => 'invalid-token' } }

          it 'returns nil' do
            result = helper_instance.runner_controller_token_from_authorization_token

            expect(result).to be_nil
          end
        end

        context 'when no token is provided' do
          let(:headers) { {} }

          it 'returns nil' do
            result = helper_instance.runner_controller_token_from_authorization_token

            expect(result).to be_nil
          end
        end
      end

      context 'when route does not allow runner_controller_token' do
        let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => runner_controller_token.token } }

        before do
          helper_instance.mock_route_setting = { runner_controller_token_allowed: false }
        end

        it 'returns nil' do
          result = helper_instance.runner_controller_token_from_authorization_token

          expect(result).to be_nil
        end
      end

      context 'when authentication_setting is empty' do
        let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => runner_controller_token.token } }

        before do
          helper_instance.mock_route_setting = {}
        end

        it 'returns nil' do
          result = helper_instance.runner_controller_token_from_authorization_token

          expect(result).to be_nil
        end
      end
    end
  end
end

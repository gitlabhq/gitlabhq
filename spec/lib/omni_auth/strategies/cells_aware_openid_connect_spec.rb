# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::CellsAwareOpenidConnect, feature_category: :system_access do
  let(:app) { ->(_env) { [200, {}, ['OK']] } }
  let(:strategy) { described_class.new(app, issuer: 'https://provider.example.com') }
  let(:state_value) { 'test_state_token' }
  let(:failure_response) { [302, { 'Location' => '/auth/failure' }, []] }

  def build_env(cookie: nil, state_param: nil)
    env = Rack::MockRequest.env_for('/users/auth/openid_connect/callback')
    env['HTTP_COOKIE'] = "omniauth_oauth_state=#{cookie}" if cookie
    env['QUERY_STRING'] = "state=#{state_param}" if state_param
    env['warden'] = instance_double(Warden::Proxy, user: nil, authenticate: nil)
    env
  end

  describe '#request_phase' do
    before do
      allow(strategy).to receive_messages(
        session: { 'omniauth.state' => state_value },
        authorize_uri: 'https://provider.example.com/auth'
      )
      allow(Gitlab.config.gitlab).to receive(:https).and_return(false)
    end

    it 'sets the oauth_state cookie with the session state' do
      _, headers, _ = strategy.request_phase

      expect(headers['Set-Cookie']).to include("omniauth_oauth_state=#{state_value}")
      expect(headers['Set-Cookie']).to match(/max-age=600/i)
      expect(headers['Set-Cookie']).to match(/samesite=lax/i)
      expect(headers['Set-Cookie']).to match(/httponly/i)
    end
  end

  describe '#callback_phase' do
    context 'when the oauth_state cookie matches the state param' do
      let(:env) { build_env(cookie: state_value, state_param: state_value) }

      before do
        allow(strategy).to receive_messages(
          env: env,
          request: Rack::Request.new(env),
          name: 'openid_connect',
          session: { 'omniauth.state' => state_value }
        )
        allow(strategy).to receive(:call_app!).and_return([200, {}, ['OK']])
      end

      it 'sets @pending_cookie_clear so call_app! will clear the oauth_state cookie' do
        strategy.callback_phase

        expect(strategy.instance_variable_get(:@pending_cookie_clear)).to be(true)
      end
    end

    shared_examples 'CSRF failure' do
      it 'fails with a CSRF error' do
        strategy.callback_phase

        expect(strategy).to have_received(:fail!).with(
          :csrf_detected,
          instance_of(OmniAuth::Strategies::OpenIDConnect::CallbackError)
        )
      end

      it 'clears the oauth_state cookie' do
        _, headers, _ = strategy.callback_phase

        expect(headers['Set-Cookie']).to match(/omniauth_oauth_state=.*max-age=0/i)
      end
    end

    context 'when the oauth_state cookie is absent' do
      let(:env) { build_env(state_param: state_value) }

      before do
        allow(strategy).to receive_messages(env: env, request: Rack::Request.new(env), name: 'openid_connect')
        allow(strategy).to receive(:fail!).and_return(failure_response)
      end

      include_examples 'CSRF failure'

      it 'logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(message: 'OAuth state cookie validation failed')
        )

        strategy.callback_phase
      end
    end

    context 'when the oauth_state cookie does not match the state param' do
      let(:env) { build_env(cookie: 'different_state', state_param: state_value) }

      before do
        allow(strategy).to receive_messages(env: env, request: Rack::Request.new(env), name: 'openid_connect')
        allow(strategy).to receive(:fail!).and_return(failure_response)
      end

      include_examples 'CSRF failure'
    end

    context 'when the state param is an array (malformed request)' do
      let(:env) do
        env = Rack::MockRequest.env_for('/users/auth/openid_connect/callback')
        env['HTTP_COOKIE'] = "omniauth_oauth_state=#{state_value}"
        env['QUERY_STRING'] = 'state[]=foo&state[]=bar'
        env
      end

      before do
        allow(strategy).to receive_messages(env: env, request: Rack::Request.new(env), name: 'openid_connect')
        allow(strategy).to receive(:fail!).and_return(failure_response)
      end

      it 'fails with a CSRF error without raising TypeError' do
        expect { strategy.callback_phase }.not_to raise_error

        expect(strategy).to have_received(:fail!).with(
          :csrf_detected,
          instance_of(OmniAuth::Strategies::OpenIDConnect::CallbackError)
        )
      end
    end
  end

  describe '#user_info' do
    subject(:strategy_instance) { described_class.new({}) }

    it 'returns user info from the id_token when available' do
      payload = { sub: '12345', email: 'user@example.com', name: 'Test User' }
      allow(strategy_instance).to receive(:decode_id_token).and_return(
        instance_double(OpenIDConnect::ResponseObject::IdToken, raw_attributes: payload)
      )
      allow(strategy_instance).to receive_message_chain(:access_token, :id_token).and_return('token')

      user_info = strategy_instance.user_info

      expect(user_info.sub).to eq('12345')
      expect(user_info.email).to eq('user@example.com')
      expect(user_info.name).to eq('Test User')
    end
  end
end

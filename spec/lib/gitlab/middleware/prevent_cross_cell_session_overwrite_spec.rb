# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::PreventCrossCellSessionOverwrite, feature_category: :cell do
  let(:fake_response) { [200, {}, ['OK']] }
  let(:fake_app) { ->(_) { fake_response } }
  let(:session_cookie_token_prefix) { 'cell-1' }
  let(:cookie_header) { nil }
  let(:warden_user) { nil }

  let(:env) do
    options = { 'HTTP_COOKIE' => cookie_header }.compact
    Rack::MockRequest.env_for('/', options).tap do |e|
      e['rack.session.options'] = {}
      e['warden'] = instance_double(Warden::Proxy, user: warden_user)
    end
  end

  subject(:middleware) { described_class.new(fake_app, session_cookie_token_prefix: session_cookie_token_prefix) }

  before do
    stub_config_cell(enabled: true, id: 1)
    allow(Rails.application.config).to receive(:session_options).and_return(key: '_gitlab_session')
  end

  describe '#call' do
    subject(:call) { middleware.call(env) }

    it 'calls the app and returns its result' do
      expect(call).to eq(fake_response)
    end

    context 'when the incoming cookie belongs to a different cell and the visitor is anonymous' do
      let(:cookie_header) { '_gitlab_session=cell-3-abc123' }

      it 'marks the session to be skipped so no Set-Cookie is written' do
        call

        expect(env['rack.session.options'][:skip]).to be(true)
      end
    end

    context 'when the incoming cookie belongs to this cell' do
      let(:cookie_header) { '_gitlab_session=cell-1-abc123' }

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end

    context 'when there is no incoming session cookie' do
      let(:cookie_header) { nil }

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end

    context 'when the cookie value does not carry a recognizable cell prefix' do
      let(:cookie_header) { '_gitlab_session=some-legacy-value' }

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end

    context 'when the visitor is authenticated on this cell' do
      let(:cookie_header) { '_gitlab_session=cell-3-abc123' }
      let(:warden_user) { instance_double(User) }

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end

    context 'when a controller allows the request to overwrite the session' do
      let(:cookie_header) { '_gitlab_session=cell-3-abc123' }

      before do
        described_class.allow_overwrite!(Rack::Request.new(env))
      end

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end

    context 'when rack.session.options is absent from env' do
      let(:cookie_header) { '_gitlab_session=cell-3-abc123' }

      before do
        env.delete('rack.session.options')
      end

      it 'returns the app result without touching the session options' do
        expect(call).to eq(fake_response)
        expect(env).not_to have_key('rack.session.options')
      end
    end

    context 'when the session cookie token prefix is blank' do
      let(:session_cookie_token_prefix) { '' }
      let(:cookie_header) { '_gitlab_session=cell-3-abc123' }

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end

    context 'when cells are not enabled' do
      let(:cookie_header) { '_gitlab_session=cell-3-abc123' }

      before do
        stub_config_cell(enabled: false, id: nil)
      end

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end

    context 'when the feature flag is disabled' do
      let(:cookie_header) { '_gitlab_session=cell-3-abc123' }

      before do
        stub_feature_flags(prevent_cross_cell_session_overwrite: false)
      end

      it 'does not skip the session write' do
        call

        expect(env['rack.session.options'][:skip]).to be_nil
      end
    end
  end
end

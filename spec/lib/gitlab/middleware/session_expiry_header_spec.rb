# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::SessionExpiryHeader, feature_category: :system_access do
  let(:expires_at) { 1.hour.from_now.to_i }
  let(:app) { ->(_env) { [200, {}, ['OK']] } }
  let(:session) { { described_class::WARDEN_SESSION_KEY => [[1], 'salt'] } }
  let(:env) { { 'rack.session' => session } }
  let(:header) { middleware.call(env)[1][described_class::HEADER] }

  subject(:middleware) { described_class.new(app) }

  before do
    allow(Gitlab::Sessions::Expiry).to receive(:expires_at).and_return(expires_at)
  end

  describe '#call' do
    it 'returns the session expiry' do
      expect(header).to eq(expires_at.to_s)
    end

    context 'when the current request wrote the session' do
      let(:committed_last_write_at) { 42 }

      before do
        session[Gitlab::Sessions::CacheStore::LAST_WRITE_AT_KEY] = 41
        env[Gitlab::Sessions::CacheStore::COMMITTED_LAST_WRITE_AT_KEY] = committed_last_write_at
      end

      it 'forwards the timestamp it wrote, not the stored one', :aggregate_failures do
        expect(Gitlab::Sessions::Expiry).to receive(:expires_at)
          .with(session, last_write_at: committed_last_write_at).and_return(expires_at)

        expect(header).to eq(expires_at.to_s)
      end
    end

    context 'when the request did not write the session' do
      let(:stored_last_write_at) { 42 }

      before do
        session[Gitlab::Sessions::CacheStore::LAST_WRITE_AT_KEY] = stored_last_write_at
      end

      it 'forwards the stored timestamp', :aggregate_failures do
        expect(Gitlab::Sessions::Expiry).to receive(:expires_at)
          .with(session, last_write_at: stored_last_write_at).and_return(expires_at)

        expect(header).to eq(expires_at.to_s)
      end
    end

    it 'passes the response through unchanged' do
      status, _headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(body).to eq(['OK'])
    end

    context 'when the session expiry cannot be derived' do
      let(:expires_at) { nil }

      it { expect(header).to be_nil }
    end

    context 'when working out the session expiry raises' do
      before do
        allow(Gitlab::Sessions::Expiry).to receive(:expires_at).and_raise(StandardError, 'expiry lookup failed')
      end

      it 'tracks the error and leaves the response as it was' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(an_instance_of(StandardError))

        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['OK'])
        expect(headers).not_to have_key(described_class::HEADER)
      end
    end

    context 'when the session has no signed in user' do
      let(:session) { {} }

      it { expect(header).to be_nil }
    end

    context 'when there is no session' do
      let(:env) { {} }

      it 'does not look up an expiry' do
        expect(Gitlab::Sessions::Expiry).not_to receive(:expires_at)
        expect(header).to be_nil
      end
    end

    context 'when the session was never loaded' do
      let(:session) { instance_double(Rack::Session::Abstract::SessionHash, loaded?: false) }

      it 'does not read the session, which would cost a lookup on anonymous requests' do
        expect(session).not_to receive(:[])
        expect(header).to be_nil
      end
    end
  end

  describe 'middleware ordering' do
    it 'runs after the session store in the application middleware stack' do
      names = Rails.application.middleware.map(&:name)

      expect(names).to include(
        'Gitlab::Middleware::SessionExpiryHeader',
        'Gitlab::Sessions::CacheStore'
      )
      expect('Gitlab::Middleware::SessionExpiryHeader')
        .to come_before('Gitlab::Sessions::CacheStore').in(names)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas::UserAccess, feature_category: :deployment_management do
  before do
    session_options = Rails.application.config.session_options

    allow(Rails.application.config).to receive(:session_options)
      .and_return(session_options.merge(session_cookie_token_prefix: 'cell1-'))
  end

  describe '.enabled?' do
    subject { described_class.enabled? }

    before do
      allow(::Gitlab::Kas).to receive(:enabled?).and_return true
    end

    it { is_expected.to be true }
  end

  describe '.{encrypt,decrypt}_public_session_id' do
    let(:data) { 'the data' }
    let(:encrypted) { described_class.encrypt_public_session_id(data) }
    let(:decrypted) { described_class.decrypt_public_session_id("cell1-#{encrypted}") }

    it { expect(encrypted).not_to include data }
    it { expect(decrypted).to eq data }
  end

  describe '.cookie_data' do
    subject(:cookie_data) { described_class.cookie_data(public_session_id) }

    let(:public_session_id) { 'the-public-session-id' }
    let(:external_k8s_proxy_url) { 'https://example.com:1234' }

    before do
      stub_config(
        gitlab: { host: 'example.com', https: true },
        gitlab_kas: { external_k8s_proxy_url: external_k8s_proxy_url }
      )
    end

    it 'adds the session cookie prefix' do
      expect(cookie_data[:value]).to start_with('cell1-')
    end

    it 'is encrypted, secure, httponly', :aggregate_failures do
      expect(cookie_data[:value]).not_to include public_session_id
      expect(cookie_data).to include(httponly: true, secure: true, path: '/')
      expect(cookie_data).not_to have_key(:domain)
    end

    context 'when on non-root path' do
      let(:external_k8s_proxy_url) { 'https://example.com/k8s-proxy' }

      it 'sets :path' do
        expect(cookie_data).to include(httponly: true, secure: true, path: '/k8s-proxy')
      end
    end

    context 'when on subdomain' do
      let(:external_k8s_proxy_url) { 'https://k8s-proxy.example.com' }

      it 'sets :domain' do
        expect(cookie_data[:domain]).to eq "example.com"
      end
    end
  end
end

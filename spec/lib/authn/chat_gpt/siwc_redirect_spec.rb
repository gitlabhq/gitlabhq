# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::ChatGpt::SiwcRedirect, feature_category: :system_access do
  describe '.enabled?' do
    subject(:enabled) { described_class.enabled? }

    before do
      allow(::Gitlab::Auth::OAuth::Provider).to receive(:enabled?).with(described_class::PROVIDER).and_return(true)
    end

    context 'when the feature flag is enabled and the provider is enabled' do
      it { is_expected.to be(true) }
    end

    context 'when the chatgpt_siwc_login_redirect feature flag is disabled' do
      before do
        stub_feature_flags(chatgpt_siwc_login_redirect: false)
      end

      it { is_expected.to be(false) }
    end

    context 'when the provider is not enabled' do
      before do
        allow(::Gitlab::Auth::OAuth::Provider)
          .to receive(:enabled?).with(described_class::PROVIDER).and_return(false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe '.trusted_request?' do
    subject(:trusted_request) { described_class.trusted_request?(request) }

    let_it_be(:redirect_uri) { 'https://chatgpt.com/connector_platform_oauth_redirect' }

    let(:request) { instance_double(ActionDispatch::Request, query_parameters: query_parameters) }
    let(:query_parameters) do
      { 'client_id' => application.uid, 'redirect_uri' => redirect_uri }
    end

    let_it_be(:application) do
      create(:oauth_application, :without_owner, redirect_uri: redirect_uri)
    end

    context 'when the client_id and redirect_uri match the connector application' do
      it { is_expected.to be(true) }
    end

    context 'when the client_id is blank' do
      let(:query_parameters) { { 'client_id' => '', 'redirect_uri' => redirect_uri } }

      it { is_expected.to be(false) }
    end

    context 'when no application matches the client_id' do
      let(:query_parameters) do
        { 'client_id' => 'does-not-exist', 'redirect_uri' => redirect_uri }
      end

      it { is_expected.to be(false) }
    end

    context 'when the request redirect_uri is not registered for the application' do
      let_it_be(:application) do
        create(:oauth_application, :without_owner, redirect_uri: 'https://example.com/callback')
      end

      it { is_expected.to be(false) }
    end

    context 'when the request redirect_uri does not match the application' do
      let(:query_parameters) do
        { 'client_id' => application.uid, 'redirect_uri' => 'http://gdk.test:3000/' }
      end

      it { is_expected.to be(false) }
    end

    context 'when the request redirect_uri host is not chatgpt.com' do
      let_it_be(:application) do
        create(:oauth_application, :without_owner, redirect_uri: 'https://evil.example.com/callback')
      end

      let(:query_parameters) do
        { 'client_id' => application.uid, 'redirect_uri' => 'https://evil.example.com/callback' }
      end

      it { is_expected.to be(false) }
    end

    context 'when the request redirect_uri is malformed' do
      let(:query_parameters) do
        { 'client_id' => application.uid, 'redirect_uri' => 'ht!tp://%%%' }
      end

      it { is_expected.to be(false) }
    end

    context 'when the request redirect_uri is blank' do
      let(:query_parameters) { { 'client_id' => application.uid } }

      it { is_expected.to be(false) }
    end

    context 'when the application is owned by a group' do
      let_it_be(:application) do
        create(:oauth_application, :group_owned, redirect_uri: redirect_uri)
      end

      it { is_expected.to be(false) }
    end

    context 'when the application is a dynamically registered client' do
      let_it_be(:application) do
        create(:oauth_application, :dynamic, redirect_uri: redirect_uri)
      end

      it { is_expected.to be(false) }
    end
  end
end

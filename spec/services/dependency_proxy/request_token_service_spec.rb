# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::RequestTokenService, feature_category: :virtual_registry do
  include DependencyProxyHelpers

  let_it_be_with_reload(:dependency_proxy_setting) { create(:dependency_proxy_group_setting) }

  let(:image) { 'alpine:3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }

  subject { described_class.new(image:, dependency_proxy_setting:).execute }

  context 'remote request is successful' do
    context 'with identity and secret set' do
      before do
        dependency_proxy_setting.update!(identity: 'i', secret: 's')
        stub_registry_auth(image, token, request_headers: dependency_proxy_setting.authorization_header)
      end

      it { expect(subject[:status]).to eq(:success) }
      it { expect(subject[:token]).to eq(token) }
    end

    context 'with identity and secret are not set' do
      before do
        dependency_proxy_setting.update!(identity: nil, secret: nil)
        stub_registry_auth(image, token, request_headers: dependency_proxy_setting.authorization_header)
      end

      it { expect(subject[:status]).to eq(:success) }
      it { expect(subject[:token]).to eq(token) }
    end
  end

  context 'remote request is not found' do
    before do
      stub_registry_auth(image, token, status: 404, request_headers: dependency_proxy_setting.authorization_header)
    end

    it { expect(subject[:status]).to eq(:error) }
    it { expect(subject[:http_status]).to eq(404) }
    it { expect(subject[:message]).to eq('Expected 200 response code for an access token') }
  end

  context 'failed to parse response body' do
    before do
      stub_registry_auth(
        image,
        token,
        status: 200,
        body: 'dasd1321: wow',
        request_headers: dependency_proxy_setting.authorization_header
      )
    end

    it { expect(subject[:status]).to eq(:error) }
    it { expect(subject[:http_status]).to eq(500) }
    it { expect(subject[:message]).to eq('Failed to parse a response body for an access token') }
  end

  context 'net timeout exception' do
    before do
      auth_link = DependencyProxy::Registry.auth_url(image)

      stub_full_request(auth_link, method: :any).to_timeout
    end

    it { expect(subject[:status]).to eq(:error) }
    it { expect(subject[:http_status]).to eq(599) }
    it { expect(subject[:message]).to eq('execution expired') }
  end
end

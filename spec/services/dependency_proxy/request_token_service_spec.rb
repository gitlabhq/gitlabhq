# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::RequestTokenService, feature_category: :virtual_registry do
  include DependencyProxyHelpers

  let(:image) { 'alpine:3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }

  subject { described_class.new(image).execute }

  context 'remote request is successful' do
    before do
      stub_registry_auth(image, token)
    end

    it { expect(subject[:status]).to eq(:success) }
    it { expect(subject[:token]).to eq(token) }
  end

  context 'remote request is not found' do
    before do
      stub_registry_auth(image, token, 404)
    end

    it { expect(subject[:status]).to eq(:error) }
    it { expect(subject[:http_status]).to eq(404) }
    it { expect(subject[:message]).to eq('Expected 200 response code for an access token') }
  end

  context 'failed to parse response body' do
    before do
      stub_registry_auth(image, token, 200, 'dasd1321: wow')
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

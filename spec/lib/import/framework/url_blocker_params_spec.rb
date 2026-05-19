# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Framework::UrlBlockerParams, feature_category: :importers do
  subject(:params) { described_class.new }

  describe '#to_h' do
    before do
      stub_application_setting(
        allow_local_requests_from_web_hooks_and_services: false,
        deny_all_requests_except_allowed: false,
        outbound_local_requests_whitelist: []
      )
    end

    it 'returns the expected keys' do
      expect(params.to_h.keys).to match_array(%i[
        allow_localhost
        allow_local_network
        schemes
        deny_all_requests_except_allowed
        outbound_local_requests_allowlist
      ])
    end

    it 'sets schemes to http and https' do
      expect(params.to_h[:schemes]).to eq(%w[http https])
    end

    context 'when allow_local_requests_from_web_hooks_and_services is false' do
      before do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
      end

      it 'sets allow_localhost and allow_local_network to false' do
        expect(params.to_h[:allow_localhost]).to be(false)
        expect(params.to_h[:allow_local_network]).to be(false)
      end
    end

    context 'when allow_local_requests_from_web_hooks_and_services is true' do
      before do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
      end

      it 'sets allow_localhost and allow_local_network to true' do
        expect(params.to_h[:allow_localhost]).to be(true)
        expect(params.to_h[:allow_local_network]).to be(true)
      end
    end

    context 'when deny_all_requests_except_allowed is false' do
      before do
        stub_application_setting(deny_all_requests_except_allowed: false)
      end

      it 'sets deny_all_requests_except_allowed to false' do
        expect(params.to_h[:deny_all_requests_except_allowed]).to be(false)
      end
    end

    context 'when deny_all_requests_except_allowed is true' do
      before do
        stub_application_setting(deny_all_requests_except_allowed: true)
      end

      it 'sets deny_all_requests_except_allowed to true' do
        expect(params.to_h[:deny_all_requests_except_allowed]).to be(true)
      end
    end

    context 'when outbound_local_requests_whitelist is set' do # rubocop:disable Naming/InclusiveLanguage -- old setting
      before do
        stub_application_setting(outbound_local_requests_whitelist: ['example.com'])
      end

      it 'reflects the allowlist' do
        expect(params.to_h[:outbound_local_requests_allowlist]).to eq(['example.com'])
      end
    end
  end
end

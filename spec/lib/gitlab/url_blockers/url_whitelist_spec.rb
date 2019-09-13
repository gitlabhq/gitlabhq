# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UrlBlockers::UrlWhitelist do
  include StubRequests

  let(:whitelist) { [] }

  before do
    allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
    stub_application_setting(outbound_local_requests_whitelist: whitelist)
  end

  describe '#domain_whitelisted?' do
    let(:whitelist) do
      [
        'www.example.com',
        'example.com'
      ]
    end

    it 'returns true if domains present in whitelist' do
      aggregate_failures do
        whitelist.each do |domain|
          expect(described_class).to be_domain_whitelisted(domain)
        end

        ['subdomain.example.com', 'example.org'].each do |domain|
          expect(described_class).not_to be_domain_whitelisted(domain)
        end
      end
    end

    it 'returns false when domain is blank' do
      expect(described_class).not_to be_domain_whitelisted(nil)
    end
  end

  describe '#ip_whitelisted?' do
    let(:whitelist) do
      [
        '0.0.0.0',
        '127.0.0.1',
        '192.168.1.1',
        '0:0:0:0:0:ffff:192.168.1.2',
        '::ffff:c0a8:102',
        'fc00:bf8b:e62c:abcd:abcd:aaaa:aaaa:aaaa',
        '0:0:0:0:0:ffff:169.254.169.254',
        '::ffff:a9fe:a9fe',
        '::ffff:a9fe:a864',
        'fe80::c800:eff:fe74:8'
      ]
    end

    it 'returns true if ips present in whitelist' do
      aggregate_failures do
        whitelist.each do |ip_address|
          expect(described_class).to be_ip_whitelisted(ip_address)
        end

        ['172.16.2.2', '127.0.0.2', 'fe80::c800:eff:fe74:9'].each do |ip_address|
          expect(described_class).not_to be_ip_whitelisted(ip_address)
        end
      end
    end

    it 'returns false when ip is blank' do
      expect(described_class).not_to be_ip_whitelisted(nil)
    end
  end
end

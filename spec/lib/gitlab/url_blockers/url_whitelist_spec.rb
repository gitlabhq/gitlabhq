# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UrlBlockers::UrlWhitelist do
  include StubRequests

  let(:whitelist) { [] }

  before do
    allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
    stub_application_setting(outbound_local_requests_whitelist: whitelist)
  end

  describe '#domain_whitelisted?' do
    let(:whitelist) { ['www.example.com', 'example.com'] }

    it 'returns true if domains present in whitelist' do
      not_whitelisted = ['subdomain.example.com', 'example.org']

      aggregate_failures do
        whitelist.each do |domain|
          expect(described_class).to be_domain_whitelisted(domain)
        end

        not_whitelisted.each do |domain|
          expect(described_class).not_to be_domain_whitelisted(domain)
        end
      end
    end

    it 'returns false when domain is blank' do
      expect(described_class).not_to be_domain_whitelisted(nil)
    end

    context 'with ports' do
      let(:whitelist) { ['example.io:3000'] }

      it 'returns true if domain and ports present in whitelist' do
        parsed_whitelist = [['example.io', { port: 3000 }]]
        not_whitelisted = [
          'example.io',
          ['example.io', { port: 3001 }]
        ]

        aggregate_failures do
          parsed_whitelist.each do |domain_and_port|
            expect(described_class).to be_domain_whitelisted(*domain_and_port)
          end

          not_whitelisted.each do |domain_and_port|
            expect(described_class).not_to be_domain_whitelisted(*domain_and_port)
          end
        end
      end
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

    context 'with ip ranges in whitelist' do
      let(:ipv4_range) { '127.0.0.0/28' }
      let(:ipv6_range) { 'fd84:6d02:f6d8:c89e::/124' }

      let(:whitelist) do
        [
          ipv4_range,
          ipv6_range
        ]
      end

      it 'does not whitelist ipv4 range when not in whitelist' do
        stub_application_setting(outbound_local_requests_whitelist: [])

        IPAddr.new(ipv4_range).to_range.to_a.each do |ip|
          expect(described_class).not_to be_ip_whitelisted(ip.to_s)
        end
      end

      it 'whitelists all ipv4s in the range when in whitelist' do
        IPAddr.new(ipv4_range).to_range.to_a.each do |ip|
          expect(described_class).to be_ip_whitelisted(ip.to_s)
        end
      end

      it 'does not whitelist ipv6 range when not in whitelist' do
        stub_application_setting(outbound_local_requests_whitelist: [])

        IPAddr.new(ipv6_range).to_range.to_a.each do |ip|
          expect(described_class).not_to be_ip_whitelisted(ip.to_s)
        end
      end

      it 'whitelists all ipv6s in the range when in whitelist' do
        IPAddr.new(ipv6_range).to_range.to_a.each do |ip|
          expect(described_class).to be_ip_whitelisted(ip.to_s)
        end
      end

      it 'does not whitelist IPs outside the range' do
        expect(described_class).not_to be_ip_whitelisted("fd84:6d02:f6d8:c89e:0:0:1:f")

        expect(described_class).not_to be_ip_whitelisted("127.0.1.15")
      end
    end

    context 'with ports' do
      let(:whitelist) { ['127.0.0.9:3000', '[2001:db8:85a3:8d3:1319:8a2e:370:7348]:443'] }

      it 'returns true if ip and ports present in whitelist' do
        parsed_whitelist = [
          ['127.0.0.9', { port: 3000 }],
          ['[2001:db8:85a3:8d3:1319:8a2e:370:7348]', { port: 443 }]
        ]
        not_whitelisted = [
          '127.0.0.9',
          ['127.0.0.9', { port: 3001 }],
          '[2001:db8:85a3:8d3:1319:8a2e:370:7348]',
          ['[2001:db8:85a3:8d3:1319:8a2e:370:7348]', { port: 3001 }]
        ]

        aggregate_failures do
          parsed_whitelist.each do |ip_and_port|
            expect(described_class).to be_ip_whitelisted(*ip_and_port)
          end

          not_whitelisted.each do |ip_and_port|
            expect(described_class).not_to be_ip_whitelisted(*ip_and_port)
          end
        end
      end
    end
  end
end

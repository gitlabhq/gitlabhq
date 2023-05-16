# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::UrlBlockers::IpAllowlistEntry, feature_category: :shared do
  let(:ipv4) { IPAddr.new('192.168.1.1') }

  describe '#initialize' do
    it 'initializes without port' do
      ip_allowlist_entry = described_class.new(ipv4)

      expect(ip_allowlist_entry.ip).to eq(ipv4)
      expect(ip_allowlist_entry.port).to be(nil)
    end

    it 'initializes with port' do
      port = 8080
      ip_allowlist_entry = described_class.new(ipv4, port: port)

      expect(ip_allowlist_entry.ip).to eq(ipv4)
      expect(ip_allowlist_entry.port).to eq(port)
    end
  end

  describe '#match?' do
    it 'matches with equivalent IP and port' do
      port = 8080
      ip_allowlist_entry = described_class.new(ipv4, port: port)

      expect(ip_allowlist_entry).to be_match(ipv4.to_s, port)
    end

    it 'matches any port when port is nil' do
      ip_allowlist_entry = described_class.new(ipv4)

      expect(ip_allowlist_entry).to be_match(ipv4.to_s, 8080)
      expect(ip_allowlist_entry).to be_match(ipv4.to_s, 9090)
    end

    it 'does not match when port is present but requested_port is nil' do
      ip_allowlist_entry = described_class.new(ipv4, port: 8080)

      expect(ip_allowlist_entry).not_to be_match(ipv4.to_s, nil)
    end

    it 'matches when port and requested_port are nil' do
      ip_allowlist_entry = described_class.new(ipv4)

      expect(ip_allowlist_entry).to be_match(ipv4.to_s)
    end

    it 'works with ipv6' do
      ipv6 = IPAddr.new('fe80::c800:eff:fe74:8')
      ip_allowlist_entry = described_class.new(ipv6)

      expect(ip_allowlist_entry).to be_match(ipv6.to_s, 8080)
    end

    it 'matches ipv4 within IPv4 range' do
      ipv4_range = IPAddr.new('127.0.0.0/28')
      ip_allowlist_entry = described_class.new(ipv4_range)

      expect(ip_allowlist_entry).to be_match(ipv4_range.to_range.last.to_s, 8080)
      expect(ip_allowlist_entry).not_to be_match('127.0.1.1', 8080)
    end

    it 'matches IPv6 within IPv6 range' do
      ipv6_range = IPAddr.new('::ffff:192.168.1.0/8')
      ip_allowlist_entry = described_class.new(ipv6_range)

      expect(ip_allowlist_entry).to be_match(ipv6_range.to_range.last.to_s, 8080)
      expect(ip_allowlist_entry).not_to be_match('fd84:6d02:f6d8:f::f', 8080)
    end

    it 'matches IPv4 to IPv6 mapped addresses in allow list' do
      ipv6_range = IPAddr.new('::ffff:192.168.1.1')
      ip_allowlist_entry = described_class.new(ipv6_range)

      expect(ip_allowlist_entry).to be_match(ipv4, 8080)
      expect(ip_allowlist_entry).to be_match(ipv6_range.to_range.last.to_s, 8080)
      expect(ip_allowlist_entry).not_to be_match('::ffff:192.168.1.0', 8080)
      expect(ip_allowlist_entry).not_to be_match('::ffff:169.254.168.101', 8080)
    end

    it 'matches IPv4 to IPv6 mapped addresses in requested IP' do
      ipv4_range = IPAddr.new('192.168.1.1/24')
      ip_allowlist_entry = described_class.new(ipv4_range)

      expect(ip_allowlist_entry).to be_match(ipv4, 8080)
      expect(ip_allowlist_entry).to be_match('::ffff:192.168.1.0', 8080)
      expect(ip_allowlist_entry).to be_match('::ffff:192.168.1.1', 8080)
      expect(ip_allowlist_entry).not_to be_match('::ffff:169.254.170.100/8', 8080)
    end
  end
end

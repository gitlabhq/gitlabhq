# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::UrlBlockers::DomainAllowlistEntry do
  let(:domain) { 'www.example.com' }

  describe '#initialize' do
    it 'initializes without port' do
      domain_allowlist_entry = described_class.new(domain)

      expect(domain_allowlist_entry.domain).to eq(domain)
      expect(domain_allowlist_entry.port).to be_nil
    end

    it 'initializes with port' do
      port = 8080
      domain_allowlist_entry = described_class.new(domain, port: port)

      expect(domain_allowlist_entry.domain).to eq(domain)
      expect(domain_allowlist_entry.port).to eq(port)
    end
  end

  describe '#match?' do
    it 'matches when domain and port are equal' do
      port = 8080
      domain_allowlist_entry = described_class.new(domain, port: port)

      expect(domain_allowlist_entry.match?(domain, port)).to be(true)
    end

    it 'matches any port when port is nil' do
      domain_allowlist_entry = described_class.new(domain)

      expect(domain_allowlist_entry.match?(domain, 8080)).to be(true)
      expect(domain_allowlist_entry.match?(domain, 9090)).to be(true)
    end

    it 'does not match when port is present but requested_port is nil' do
      domain_allowlist_entry = described_class.new(domain, port: 8080)

      expect(domain_allowlist_entry.match?(domain, nil)).to be(false)
    end

    it 'matches when port and requested_port are nil' do
      domain_allowlist_entry = described_class.new(domain)

      expect(domain_allowlist_entry.match?(domain)).to be(true)
    end

    it 'does not match if domain is not equal' do
      domain_allowlist_entry = described_class.new(domain)

      expect(domain_allowlist_entry.match?('www.gitlab.com', 8080)).to be(false)
    end
  end
end

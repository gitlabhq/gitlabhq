# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::SrvResolver do
  let(:resolver) { Net::DNS::Resolver.new(nameservers: '127.0.0.1', port: 8600, use_tcp: true) }
  let(:additional) { dns_response_packet_from_fixture('srv_with_a_rr_in_additional_section').additional }

  describe '#address_for' do
    let(:host) { 'patroni-02-db-gstg.node.east-us-2.consul.' }

    subject { described_class.new(resolver, additional).address_for(host) }

    context 'when additional section contains an A record' do
      it 'returns an IP4 address' do
        expect(subject).to eq(IPAddr.new('10.224.29.102'))
      end
    end

    context 'when additional section contains an AAAA record' do
      let(:host) { 'a.gtld-servers.net.' }
      let(:additional) { dns_response_packet_from_fixture('a_with_aaaa_rr_in_additional_section').additional }

      it 'returns an IP6 address' do
        expect(subject).to eq(IPAddr.new('2001:503:a83e::2:30'))
      end
    end

    context 'when additional section does not contain A nor AAAA records' do
      let(:additional) { [] }

      context 'when host resolves to an A record' do
        before do
          allow(resolver).to receive(:search).with(host, Net::DNS::ANY).and_return(dns_response_packet_from_fixture('a_rr'))
        end

        it 'returns an IP4 address' do
          expect(subject).to eq(IPAddr.new('10.224.29.102'))
        end
      end

      context 'when host does resolves to an AAAA record' do
        before do
          allow(resolver).to receive(:search).with(host, Net::DNS::ANY).and_return(dns_response_packet_from_fixture('aaaa_rr'))
        end

        it 'returns an IP6 address' do
          expect(subject).to eq(IPAddr.new('2a00:1450:400e:80a::200e'))
        end
      end
    end
  end

  def dns_response_packet_from_fixture(fixture_name)
    fixture         = File.read(Rails.root + "spec/fixtures/dns/#{fixture_name}.json")
    encoded_payload = Gitlab::Json.parse(fixture)['payload']
    payload         = Base64.decode64(encoded_payload)

    Net::DNS::Packet.parse(payload)
  end
end

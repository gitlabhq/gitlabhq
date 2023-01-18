# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Resolver, :freeze_time, feature_category: :database do
  describe '#resolve' do
    let(:ip_addr) { IPAddr.new('127.0.0.2') }

    context 'when nameserver is an IP' do
      it 'returns an IPAddr object' do
        service = described_class.new('127.0.0.2')
        response = service.resolve

        expect(response.address).to eq(ip_addr)
      end
    end

    context 'when nameserver is not an IP' do
      subject { described_class.new('localhost').resolve }

      it 'looks the nameserver up in the hosts file' do
        allow_next_instance_of(Resolv::Hosts) do |instance|
          allow(instance).to receive(:getaddress).with('localhost').and_return('127.0.0.2')
        end

        expect(subject.address).to eq(ip_addr)
      end

      context 'when nameserver is not in the hosts file' do
        let(:raw_ttl) { 10 }

        it 'looks the nameserver up in DNS' do
          resource = double(:resource, address: ip_addr, ttl: raw_ttl)
          packet = double(:packet, answer: [resource])

          allow_next_instance_of(Resolv::Hosts) do |instance|
            allow(instance).to receive(:getaddress).with('localhost').and_raise(Resolv::ResolvError)
          end

          allow(Net::DNS::Resolver).to receive(:start)
            .with('localhost', Net::DNS::A)
            .and_return(packet)

          expect(subject.address).to eq(ip_addr)
          expect(subject.ttl).to eq(raw_ttl.seconds.from_now)
        end

        context 'when nameserver is not in DNS' do
          it 'raises an exception' do
            allow_next_instance_of(Resolv::Hosts) do |instance|
              allow(instance).to receive(:getaddress).with('localhost').and_raise(Resolv::ResolvError)
            end

            allow(Net::DNS::Resolver).to receive(:start)
              .with('localhost', Net::DNS::A)
              .and_return(double(:packet, answer: []))

            expect { subject }.to raise_exception(
              described_class::UnresolvableNameserverError,
              'could not resolve localhost'
            )
          end
        end

        context 'when DNS does not respond' do
          it 'raises an exception' do
            allow_next_instance_of(Resolv::Hosts) do |instance|
              allow(instance).to receive(:getaddress).with('localhost').and_raise(Resolv::ResolvError)
            end

            allow(Net::DNS::Resolver).to receive(:start)
              .with('localhost', Net::DNS::A)
              .and_raise(Net::DNS::Resolver::NoResponseError)

            expect { subject }.to raise_exception(
              described_class::UnresolvableNameserverError,
              'no response from DNS server(s)'
            )
          end
        end
      end
    end
  end
end

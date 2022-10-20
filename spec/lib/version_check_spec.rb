# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VersionCheck do
  describe '.url' do
    it 'returns the correct URL' do
      expect(described_class.url).to match(%r{\A#{Regexp.escape(described_class.host)}/check\.json\?gitlab_info=\w+})
    end
  end

  context 'reactive cache properties' do
    describe '.reactive_cache_refresh_interval' do
      it 'returns 12.hours' do
        expect(described_class.reactive_cache_refresh_interval).to eq(12.hours)
      end
    end

    describe '.reactive_cache_lifetime' do
      it 'returns 7.days' do
        expect(described_class.reactive_cache_lifetime).to eq(7.days)
      end
    end
  end

  describe '#calculate_reactive_cache' do
    context 'response code is 200' do
      before do
        stub_request(:get, described_class.url).to_return(status: 200, body: '{ "status": "success" }', headers: {})
      end

      it 'returns the response object' do
        expect(described_class.new.calculate_reactive_cache).to eq("{ \"status\": \"success\" }")
      end
    end

    context 'response code is not 200' do
      before do
        stub_request(:get, described_class.url).to_return(status: 500, body: nil, headers: {})
      end

      it 'returns nil' do
        expect(described_class.new.calculate_reactive_cache).to be(nil)
      end
    end
  end

  describe '#response' do
    context 'cache returns value' do
      let(:response) { { "severity" => "success" }.to_json }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:with_reactive_cache).and_return(response)
        end
      end

      it 'returns the response object' do
        expect(described_class.new.response).to be(response)
      end
    end

    context 'cache returns nil' do
      let(:response) { nil }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:with_reactive_cache).and_return(response)
        end
      end

      it 'returns nil' do
        expect(described_class.new.response).to be(nil)
      end
    end
  end
end

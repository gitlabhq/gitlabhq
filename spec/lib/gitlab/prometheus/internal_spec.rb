# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Prometheus::Internal do
  let(:server_address) { 'localhost:9090' }

  let(:prometheus_settings) do
    {
      enabled: true,
      server_address: server_address
    }
  end

  before do
    stub_config(prometheus: prometheus_settings)
  end

  describe '.uri' do
    shared_examples 'returns valid uri' do |uri_string|
      it do
        expect(described_class.uri).to eq(uri_string)
        expect { Addressable::URI.parse(described_class.uri) }.not_to raise_error
      end
    end

    it_behaves_like 'returns valid uri', 'http://localhost:9090'

    context 'with non default prometheus address' do
      let(:server_address) { 'https://localhost:9090' }

      it_behaves_like 'returns valid uri', 'https://localhost:9090'

      context 'with :9090 symbol' do
        let(:server_address) { :':9090' }

        it_behaves_like 'returns valid uri', 'http://localhost:9090'
      end

      context 'with 0.0.0.0:9090' do
        let(:server_address) { '0.0.0.0:9090' }

        it_behaves_like 'returns valid uri', 'http://localhost:9090'
      end
    end

    context 'when server_address is nil' do
      let(:server_address) { nil }

      it 'does not fail' do
        expect(described_class.uri).to be_nil
      end
    end

    context 'when prometheus listen address is blank in gitlab.yml' do
      let(:server_address) { '' }

      it 'does not configure prometheus' do
        expect(described_class.uri).to be_nil
      end
    end
  end

  describe '.prometheus_enabled?' do
    it 'returns correct value' do
      expect(described_class.prometheus_enabled?).to eq(true)
    end

    context 'when prometheus setting is disabled in gitlab.yml' do
      let(:prometheus_settings) do
        {
          enabled: false,
          server_address: server_address
        }
      end

      it 'returns correct value' do
        expect(described_class.prometheus_enabled?).to eq(false)
      end
    end

    context 'when prometheus setting is not present in gitlab.yml' do
      before do
        allow(Gitlab.config).to receive(:prometheus).and_raise(GitlabSettings::MissingSetting)
      end

      it 'does not fail' do
        expect(described_class.prometheus_enabled?).to eq(false)
      end
    end
  end

  describe '.server_address' do
    it 'returns correct value' do
      expect(described_class.server_address).to eq(server_address)
    end

    context 'when prometheus setting is not present in gitlab.yml' do
      before do
        allow(Gitlab.config).to receive(:prometheus).and_raise(GitlabSettings::MissingSetting)
      end

      it 'does not fail' do
        expect(described_class.server_address).to be_nil
      end
    end
  end
end

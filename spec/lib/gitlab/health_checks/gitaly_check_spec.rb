# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::HealthChecks::GitalyCheck do
  let(:result_class) { Gitlab::HealthChecks::Result }

  describe '#readiness' do
    subject { described_class.readiness }

    before do
      expect(Gitlab::GitalyClient::HealthCheckService).to receive(:new).and_return(gitaly_check)
    end

    context 'Gitaly server is up' do
      let(:gitaly_check) { double(check: { success: true }) }

      it { is_expected.to eq([result_class.new('gitaly_check', true, nil, shard: 'default')]) }
    end

    context 'Gitaly server is down' do
      let(:gitaly_check) { double(check: { success: false, message: 'Connection refused' }) }

      it { is_expected.to eq([result_class.new('gitaly_check', false, 'Connection refused', shard: 'default')]) }
    end
  end

  describe '#metrics' do
    subject { described_class.metrics }

    let(:server) { double(storage: 'default', read_writeable?: up) }

    before do
      allow(Gitaly::Server).to receive(:new).and_return(server)
    end

    context 'Gitaly server is up' do
      let(:up) { true }

      it 'provides metrics' do
        expect(subject).to all(have_attributes(labels: { shard: 'default' }))
        expect(subject).to include(an_object_having_attributes(name: 'gitaly_health_check_success', value: 1))
        expect(subject).to include(an_object_having_attributes(name: 'gitaly_health_check_latency_seconds', value: be >= 0))
      end
    end

    context 'Gitaly server is down' do
      let(:up) { false }

      it 'provides metrics' do
        expect(subject).to include(an_object_having_attributes(name: 'gitaly_health_check_success', value: 0))
        expect(subject).to include(an_object_having_attributes(name: 'gitaly_health_check_latency_seconds', value: be >= 0))
      end
    end
  end
end

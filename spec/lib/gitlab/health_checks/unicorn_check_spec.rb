# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::HealthChecks::UnicornCheck do
  let(:result_class) { Gitlab::HealthChecks::Result }
  let(:readiness) { described_class.readiness }
  let(:metrics) { described_class.metrics }

  before do
    described_class.clear_memoization(:http_servers)
  end

  shared_examples 'with state' do |(state, message)|
    it "does provide readiness" do
      expect(readiness).to eq(result_class.new('unicorn_check', state, message))
    end

    it "does provide metrics" do
      expect(metrics).to include(
        an_object_having_attributes(name: 'unicorn_check_success', value: state ? 1 : 0))
      expect(metrics).to include(
        an_object_having_attributes(name: 'unicorn_check_latency_seconds', value: be >= 0))
    end
  end

  context 'when Unicorn is not loaded' do
    before do
      hide_const('Unicorn')
    end

    it "does not provide readiness and metrics" do
      expect(readiness).to be_nil
      expect(metrics).to be_nil
    end
  end

  context 'when Unicorn is loaded' do
    let(:http_server_class) { Struct.new(:worker_processes) }

    before do
      stub_const('Unicorn::HttpServer', http_server_class)
    end

    context 'when no servers are running' do
      it_behaves_like 'with state', [false, 'unexpected Unicorn check result: 0']
    end

    context 'when servers without workers are running' do
      before do
        http_server_class.new(0)
      end

      it_behaves_like 'with state', [false, 'unexpected Unicorn check result: 0']
    end

    context 'when servers with workers are running' do
      before do
        http_server_class.new(1)
      end

      it_behaves_like 'with state', true
    end
  end
end

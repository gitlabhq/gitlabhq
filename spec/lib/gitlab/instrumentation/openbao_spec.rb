# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::Openbao, :request_store, feature_category: :secrets_management do
  let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }
  let(:errors_counter) { instance_double(Prometheus::Client::Counter, increment: nil) }
  let(:histogram) { instance_double(Prometheus::Client::Histogram, observe: nil) }

  # The metric objects are memoized per process, so drop them or the doubles
  # below are ignored once another example has already built the real ones.
  # Dropping them again on the way out keeps the doubles from leaking into
  # whichever spec file rspec loads next.
  def drop_memoized_metrics
    %i[@requests_total @request_duration_seconds @request_errors_total].each do |ivar|
      described_class.remove_instance_variable(ivar) if described_class.instance_variable_defined?(ivar)
    end
  end

  before do
    allow(Gitlab::Metrics::OpenbaoClientSlis).to receive(:record_error_rate)
    allow(Gitlab::Metrics).to receive(:histogram).and_return(histogram)

    # A double per metric name, so an increment landing on the wrong counter
    # cannot be absorbed by the other one's permissive stub.
    allow(Gitlab::Metrics).to receive(:counter) do |name, _description|
      name == :gitlab_openbao_request_errors_total ? errors_counter : counter
    end

    drop_memoized_metrics
  end

  after do
    drop_memoized_metrics
  end

  describe '.get_request_count' do
    it 'returns zero when no call was recorded' do
      expect(described_class.get_request_count).to eq(0)
    end

    it 'counts every recorded call' do
      2.times { described_class.add_call(duration: 0.1, path: 'sys/health', method: :get, outcome: :success) }

      expect(described_class.get_request_count).to eq(2)
    end
  end

  describe '.query_time' do
    it 'returns zero when no call was recorded' do
      expect(described_class.query_time).to eq(0)
    end

    it 'accumulates the duration of every recorded call' do
      described_class.add_call(duration: 0.1, path: 'sys/health', method: :get, outcome: :success)
      described_class.add_call(duration: 0.25, path: 'sys/health', method: :get, outcome: :success)

      expect(described_class.query_time).to eq(0.35)
    end

    it 'rounds to the shared duration precision' do
      described_class.add_call(duration: 0.1234567891, path: 'sys/health', method: :get, outcome: :success)

      expect(described_class.query_time).to eq(0.123457)
    end
  end

  describe '.add_call' do
    it 'builds the metrics under the documented names and buckets' do
      described_class.add_call(duration: 0.1, path: 'sys/health', method: :get, outcome: :success)

      expect(Gitlab::Metrics).to have_received(:counter).with(
        :gitlab_openbao_requests_total, anything
      )
      expect(Gitlab::Metrics).to have_received(:histogram).with(
        :gitlab_openbao_request_duration_seconds, anything, {}, described_class::DURATION_BUCKETS
      )
    end

    it 'increments the counter with bounded labels' do
      expect(counter).to receive(:increment).with(
        operation: 'kv/data', method: 'post', outcome: 'success'
      )

      described_class.add_call(
        duration: 0.1, path: 'org_1/ns_2/project_3/kv/data/MY_SECRET', method: :post, outcome: :success
      )
    end

    it 'records the outcome of a failed call' do
      expect(counter).to receive(:increment).with(
        operation: 'sys/mounts', method: 'post', outcome: 'error'
      )

      described_class.add_call(duration: 0.1, path: 'sys/mounts/kv_mount', method: :post, outcome: :error)
    end

    it 'observes the duration against the operation and outcome' do
      expect(histogram).to receive(:observe).with({ operation: 'sys/mounts', outcome: 'success' }, 0.42)

      described_class.add_call(duration: 0.42, path: 'sys/mounts/kv_mount', method: :post, outcome: :success)
    end

    it 'records the error rate SLI against the same operation' do
      expect(Gitlab::Metrics::OpenbaoClientSlis).to receive(:record_error_rate).with(
        operation: 'sys/mounts', error: true
      )

      described_class.add_call(duration: 0.1, path: 'sys/mounts/kv_mount', method: :post, outcome: :error)
    end

    it 'records a successful call as a non-error on the SLI' do
      expect(Gitlab::Metrics::OpenbaoClientSlis).to receive(:record_error_rate).with(
        operation: 'kv/data', error: false
      )

      described_class.add_call(
        duration: 0.1, path: 'org_1/ns_2/project_3/kv/data/MY_SECRET', method: :post, outcome: :success
      )
    end

    # Without `outcome` on the histogram, a failing OpenBao lowers every
    # percentile: failures return in milliseconds while successes wait on
    # OpenBao's synchronous audit POSTs back into Rails.
    it 'separates failed durations from successful ones' do
      expect(histogram).to receive(:observe).with({ operation: 'sys/mounts', outcome: 'error' }, 0.01)

      described_class.add_call(duration: 0.01, path: 'sys/mounts/kv_mount', method: :post, outcome: :error)
    end

    context 'with a fault type' do
      it 'builds the sibling error counter under the documented name' do
        described_class.add_call(
          duration: 0.1, path: 'sys/health', method: :get, outcome: :error, error_type: 'timeout'
        )

        expect(Gitlab::Metrics).to have_received(:counter).with(
          :gitlab_openbao_request_errors_total, anything
        )
      end

      it 'increments the error counter with bounded labels' do
        expect(counter).to receive(:increment).with(
          operation: 'sys/mounts', method: 'post', outcome: 'error'
        )
        expect(errors_counter).to receive(:increment).with(
          operation: 'sys/mounts', error_type: 'timeout'
        )

        described_class.add_call(
          duration: 0.1, path: 'sys/mounts/kv_mount', method: :post, outcome: :error, error_type: 'timeout'
        )
      end

      it 'leaves the error counter alone when no fault type is given' do
        expect(counter).to receive(:increment).with(
          operation: 'sys/mounts', method: 'post', outcome: 'error'
        )
        expect(errors_counter).not_to receive(:increment)

        described_class.add_call(duration: 0.1, path: 'sys/mounts/kv_mount', method: :post, outcome: :error)
      end
    end

    context 'when the request store is not active' do
      before do
        allow(::Gitlab::SafeRequestStore).to receive(:active?).and_return(false)
      end

      it 'still records the Prometheus metrics' do
        expect(counter).to receive(:increment)
        expect(histogram).to receive(:observe)

        described_class.add_call(duration: 0.1, path: 'sys/health', method: :get, outcome: :success)
      end

      it 'does not raise, and leaves the request-log counters empty' do
        expect { described_class.add_call(duration: 0.1, path: 'sys/health', method: :get, outcome: :success) }
          .not_to raise_error

        expect(described_class.get_request_count).to eq(0)
        expect(described_class.query_time).to eq(0)
      end
    end
  end

  describe '.operation_for' do
    # Every path shape SecretsManagerClient actually sends, plus the namespaced
    # forms. The point of each case is that no project, group or secret name
    # survives into the returned value.
    where(:path, :expected) do
      [
        ['sys/namespaces/org_1/ns_2', 'sys/namespaces'],
        ['sys/mounts/project_3_secrets', 'sys/mounts'],
        ['sys/auth/project_3_jwt', 'sys/auth'],
        ['sys/policies/acl/project_3_secret_MY_TOKEN', 'sys/policies'],
        ['sys/policies/detailed/acl/project_3', 'sys/policies'],
        ['sys/capabilities-self', 'sys/capabilities-self'],
        ['sys/health', 'sys/health'],
        ['sys/rotate/recovery/init', 'sys/rotate'],
        ['org_1/ns_2/project_3/sys/capabilities-self', 'sys/capabilities-self'],
        ['sys/something-new/project_3', 'sys/other'],
        ['sys', 'sys/other'],
        ['project_3_secrets/data/MY_SECRET', 'kv/data'],
        ['project_3_secrets/metadata/MY_SECRET', 'kv/metadata'],
        ['project_3_secrets/detailed-metadata/MY_SECRET', 'kv/detailed-metadata'],
        ['org_1/ns_2/project_3/project_3_secrets/data/MY_SECRET', 'kv/data'],
        ['auth/project_3_jwt/config', 'auth/config'],
        ['auth/gitlab_rails_jwt/role/app', 'auth/role'],
        ['auth/project_3_jwt/cel/role/project_3_role', 'auth/role'],
        ['auth/project_3_jwt/cel/login', 'auth/login'],
        ['org_1/ns_2/project_3/auth/token/revoke-self', 'auth/revoke-self'],
        ['auth/project_3_jwt/something-new', 'auth/other'],
        ['something/entirely/unexpected', 'other'],
        ['', 'other'],
        [nil, 'other']
      ]
    end

    with_them do
      it { expect(described_class.operation_for(path)).to eq(expected) }
    end

    # Secret names allow [a-zA-Z0-9_], so `sys` and `auth` are both legal names.
    it 'does not let a secret name decide the label' do
      expect(described_class.operation_for('secrets/kv/data/explicit/sys')).to eq('kv/data')
      expect(described_class.operation_for('project_3_secrets/data/auth')).to eq('kv/data')
      expect(described_class.operation_for('project_3_secrets/metadata/sys')).to eq('kv/metadata')
    end

    it 'never leaks an identifier or a secret name into the label' do
      path = 'org_99/ns_88/project_77/project_77_secrets/data/PRODUCTION_DB_PASSWORD'

      operation = described_class.operation_for(path)

      expect(operation).to eq('kv/data')
      expect(operation).not_to include('99', '88', '77', 'PRODUCTION_DB_PASSWORD')
    end
  end
end

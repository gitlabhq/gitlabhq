# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::OpenbaoClientSlis, feature_category: :secrets_management do
  describe '.initialize_slis!' do
    it 'initializes the openbao_client_calls error rate SLI with one label set per operation' do
      expected_labels = Gitlab::Instrumentation::Openbao::ALL_OPERATIONS.map { |op| { operation: op } }

      expect(Gitlab::Metrics::Sli::ErrorRate)
        .to receive(:initialize_sli).with(:openbao_client_calls, expected_labels)

      described_class.initialize_slis!
    end

    it 'pre-initializes every operation the instrumentation can emit' do
      paths = [
        'sys/namespaces', 'sys/mounts', 'sys/auth', 'sys/policies', 'sys/capabilities-self',
        'sys/health', 'sys/rotate', 'sys/something-else',
        'auth/jwt/login', 'auth/jwt/role/x', 'auth/jwt/config', 'auth/token/revoke-self', 'auth/jwt/other',
        'ns/mount/data/secret', 'ns/mount/metadata/secret', 'ns/mount/detailed-metadata/secret',
        'no/structural/segment'
      ]

      emitted = paths.map { |path| Gitlab::Instrumentation::Openbao.operation_for(path) }.uniq

      expect(Gitlab::Instrumentation::Openbao::ALL_OPERATIONS).to include(*emitted)
    end
  end

  describe '.record_error_rate' do
    it 'increments the error rate SLI with the operation label' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:openbao_client_calls]).to receive(:increment).with(
        labels: { operation: 'kv/data' },
        error: true
      )

      described_class.record_error_rate(operation: 'kv/data', error: true)
    end

    it 'records a success when there is no error' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:openbao_client_calls]).to receive(:increment).with(
        labels: { operation: 'kv/data' },
        error: false
      )

      described_class.record_error_rate(operation: 'kv/data', error: false)
    end
  end
end

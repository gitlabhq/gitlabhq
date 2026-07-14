# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GitalyClientSlis, feature_category: :gitaly do
  describe '.initialize_slis!' do
    it 'initializes the gitaly_client_calls error rate SLI' do
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:gitaly_client_calls, [])

      described_class.initialize_slis!
    end
  end

  describe '.record_error_rate' do
    before do
      allow(described_class).to receive(:node_label).with('default').and_return('gitaly-01-stor.example')
    end

    it 'increments the error rate SLI with the gitaly_node label derived from the storage' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:gitaly_client_calls]).to receive(:increment).with(
        labels: { gitaly_node: 'gitaly-01-stor.example' },
        error: true
      )

      described_class.record_error_rate(storage: 'default', error: GRPC::Unavailable.new)
    end

    it 'records a success when there is no error' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:gitaly_client_calls]).to receive(:increment).with(
        labels: { gitaly_node: 'gitaly-01-stor.example' },
        error: false
      )

      described_class.record_error_rate(storage: 'default')
    end
  end

  describe '.node_label' do
    using RSpec::Parameterized::TableSyntax

    def stub_repos_storages(address)
      allow(Gitlab.config.repositories).to receive(:storages).and_return({
        'default' => { 'gitaly_address' => address }
      })
    end

    where(:address, :expected_node_label) do
      'tcp://gitaly-01-stor.example.internal:9999' | 'gitaly-01-stor.example.internal'
      'tls://gitaly-02-stor.example.internal:8075' | 'gitaly-02-stor.example.internal'
      'tcp://localhost:9876'                       | 'localhost'
      # Schemes without a parseable host fall back to the storage name.
      'unix:tmp/gitaly.sock'                       | 'default'
      'dns:///localhost:9876'                      | 'default'
      'dns:localhost:9876'                         | 'default'
    end

    with_them do
      it 'returns a node label that lines up with the server-side fqdn' do
        stub_repos_storages(address)

        expect(described_class.node_label('default')).to eq(expected_node_label)
      end
    end

    it 'falls back to the storage name when the address is invalid' do
      allow(::Gitlab::GitalyClient).to receive(:address).with('default').and_return('::not a uri::')

      expect(described_class.node_label('default')).to eq('default')
    end
  end

  describe '.error?' do
    it 'is not an error when there is no exception' do
      expect(described_class.error?(nil)).to be(false)
    end

    it 'is an error for a non-gRPC exception' do
      expect(described_class.error?(StandardError.new)).to be(true)
    end

    it 'is an error for the circuit-breaker fast-fail' do
      expect(described_class.error?(Gitlab::Git::ResourceExhaustedError.new)).to be(true)
    end

    context 'with a GRPC::BadStatus exception' do
      using RSpec::Parameterized::TableSyntax

      where(:error_class, :is_error) do
        GRPC::Cancelled          | false
        GRPC::InvalidArgument    | false
        GRPC::DeadlineExceeded   | true
        GRPC::NotFound           | false
        GRPC::AlreadyExists      | false
        GRPC::PermissionDenied   | false
        GRPC::FailedPrecondition | false
        GRPC::Unauthenticated    | false
        GRPC::Unknown            | true
        GRPC::Aborted            | true
        GRPC::OutOfRange         | true
        GRPC::Unimplemented      | true
        GRPC::Internal           | true
        GRPC::Unavailable        | true
        GRPC::DataLoss           | true
        # ResourceExhausted is ignored server-side but counts as an error here.
        GRPC::ResourceExhausted  | true
      end

      with_them do
        it "returns #{params[:is_error]} for #{params[:error_class]}" do
          expect(described_class.error?(error_class.new)).to eq(is_error)
        end
      end
    end
  end
end

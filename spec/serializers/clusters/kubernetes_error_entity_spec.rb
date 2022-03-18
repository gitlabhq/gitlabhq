# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::KubernetesErrorEntity do
  describe '#as_json' do
    let(:cluster) { create(:cluster, :provided_by_user, :group) }

    subject { described_class.new(cluster).as_json }

    context 'when connection_error is present' do
      before do
        allow(cluster).to receive(:connection_error).and_return(:connection_error)
      end

      it { is_expected.to eq({ connection_error: :connection_error, metrics_connection_error: nil, node_connection_error: nil }) }
    end

    context 'when metrics_connection_error is present' do
      before do
        allow(cluster).to receive(:metrics_connection_error).and_return(:http_error)
      end

      it { is_expected.to eq({ connection_error: nil, metrics_connection_error: :http_error, node_connection_error: nil }) }
    end

    context 'when node_connection_error is present' do
      before do
        allow(cluster).to receive(:node_connection_error).and_return(:unknown_error)
      end

      it { is_expected.to eq({ connection_error: nil, metrics_connection_error: nil, node_connection_error: :unknown_error }) }
    end
  end
end

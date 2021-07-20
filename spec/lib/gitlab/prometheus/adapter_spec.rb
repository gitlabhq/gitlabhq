# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Prometheus::Adapter do
  let_it_be(:project) { create(:project) }
  let_it_be(:cluster, reload: true) { create(:cluster, :provided_by_user, environment_scope: '*', projects: [project]) }

  subject { described_class.new(project, cluster) }

  describe '#prometheus_adapter' do
    context 'prometheus integration can execute queries' do
      let(:prometheus_integration) { double(:prometheus_integration, can_query?: true) }

      before do
        allow(project).to receive(:find_or_initialize_integration).with('prometheus').and_return prometheus_integration
      end

      it 'return prometheus integration as prometheus adapter' do
        expect(subject.prometheus_adapter).to eq(prometheus_integration)
      end

      context 'with cluster with prometheus available' do
        let!(:prometheus) { create(:clusters_integrations_prometheus, cluster: cluster) }

        it 'returns prometheus integration' do
          expect(subject.prometheus_adapter).to eq(prometheus_integration)
        end
      end
    end

    context "prometheus integration can't execute queries" do
      let(:prometheus_integration) { double(:prometheus_integration, can_query?: false) }

      before do
        allow(project).to receive(:find_or_initialize_integration).with('prometheus').and_return prometheus_integration
      end

      context 'with cluster with prometheus disabled' do
        let!(:prometheus) { create(:clusters_integrations_prometheus, enabled: false, cluster: cluster) }

        it 'returns nil' do
          expect(subject.prometheus_adapter).to be_nil
        end
      end

      context 'with cluster with prometheus available' do
        let!(:prometheus) { create(:clusters_integrations_prometheus, cluster: cluster) }

        it 'returns application handling all environments' do
          expect(subject.prometheus_adapter).to eq(prometheus)
        end
      end

      context 'with cluster without prometheus installed' do
        it 'returns nil' do
          expect(subject.prometheus_adapter).to be_nil
        end
      end
    end
  end
end

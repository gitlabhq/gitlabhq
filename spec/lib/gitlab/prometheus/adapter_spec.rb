# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Prometheus::Adapter do
  let_it_be(:project) { create(:project) }
  let_it_be(:cluster, reload: true) { create(:cluster, :provided_by_user, environment_scope: '*', projects: [project]) }

  subject { described_class.new(project, cluster) }

  describe '#prometheus_adapter' do
    context 'prometheus service can execute queries' do
      let(:prometheus_service) { double(:prometheus_service, can_query?: true) }

      before do
        allow(project).to receive(:find_or_initialize_service).with('prometheus').and_return prometheus_service
      end

      it 'return prometheus service as prometheus adapter' do
        expect(subject.prometheus_adapter).to eq(prometheus_service)
      end

      context 'with cluster with prometheus available' do
        let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

        it 'returns prometheus service' do
          expect(subject.prometheus_adapter).to eq(prometheus_service)
        end
      end
    end

    context "prometheus service can't execute queries" do
      let(:prometheus_service) { double(:prometheus_service, can_query?: false) }

      context 'with cluster with prometheus integration' do
        let!(:prometheus_integration) { create(:clusters_integrations_prometheus, cluster: cluster) }

        it 'returns the integration' do
          expect(subject.prometheus_adapter).to eq(prometheus_integration)
        end
      end

      context 'with cluster with prometheus not available' do
        let!(:prometheus) { create(:clusters_applications_prometheus, :installable, cluster: cluster) }

        it 'returns nil' do
          expect(subject.prometheus_adapter).to be_nil
        end
      end

      context 'with cluster with prometheus available' do
        let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

        it 'returns application handling all environments' do
          expect(subject.prometheus_adapter).to eq(prometheus)
        end

        context 'with cluster with prometheus integration' do
          let!(:prometheus_integration) { create(:clusters_integrations_prometheus, cluster: cluster) }

          it 'returns the application' do
            expect(subject.prometheus_adapter).to eq(prometheus)
          end
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

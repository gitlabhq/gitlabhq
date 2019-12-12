# frozen_string_literal: true

require 'spec_helper'

describe Prometheus::AdapterService do
  let(:project) { create(:project) }

  subject { described_class.new(project) }

  describe '#prometheus_adapter' do
    let(:cluster) { create(:cluster, :provided_by_user, environment_scope: '*', projects: [project]) }

    context 'prometheus service can execute queries' do
      let(:prometheus_service) { double(:prometheus_service, can_query?: true) }

      before do
        allow(project).to receive(:find_or_initialize_service).with('prometheus').and_return prometheus_service
      end

      it 'return prometheus service as prometheus adapter' do
        expect(subject.prometheus_adapter).to eq(prometheus_service)
      end
    end

    context "prometheus service can't execute queries" do
      let(:prometheus_service) { double(:prometheus_service, can_query?: false) }

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
      end

      context 'with cluster without prometheus installed' do
        it 'returns nil' do
          expect(subject.prometheus_adapter).to be_nil
        end
      end
    end
  end
end

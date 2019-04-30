# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::DestroyService, '#execute' do
  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:user) { create(:user) }
  let(:params) { { application: 'prometheus' } }
  let(:service) { described_class.new(cluster, user, params) }
  let(:test_request) { double }
  let(:worker_class) { Clusters::Applications::UninstallWorker }

  subject { service.execute(test_request) }

  before do
    allow(worker_class).to receive(:perform_async)
  end

  context 'application is not installed' do
    it 'raises Clusters::Applications::BaseService::InvalidApplicationError' do
      expect(worker_class).not_to receive(:perform_async)

      expect { subject }
        .to raise_exception { Clusters::Applications::BaseService::InvalidApplicationError }
        .and not_change { Clusters::Applications::Prometheus.count }
        .and not_change { Clusters::Applications::Prometheus.with_status(:scheduled).count }
    end
  end

  context 'application is installed' do
    context 'application is schedulable' do
      let!(:application) do
        create(:clusters_applications_prometheus, :installed, cluster: cluster)
      end

      it 'makes application scheduled!' do
        subject

        expect(application.reload).to be_scheduled
      end

      it 'schedules UninstallWorker' do
        expect(worker_class).to receive(:perform_async).with(application.name, application.id)

        subject
      end
    end

    context 'application is not schedulable' do
      let!(:application) do
        create(:clusters_applications_prometheus, :updating, cluster: cluster)
      end

      it 'raises StateMachines::InvalidTransition' do
        expect(worker_class).not_to receive(:perform_async)

        expect { subject }
          .to raise_exception { StateMachines::InvalidTransition }
          .and not_change { Clusters::Applications::Prometheus.with_status(:scheduled).count }
      end
    end
  end
end

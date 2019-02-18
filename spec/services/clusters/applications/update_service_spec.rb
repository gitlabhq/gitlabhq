# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::UpdateService do
  include TestRequestHelpers

  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:user) { create(:user) }
  let(:params) { { application: 'knative', hostname: 'udpate.example.com' } }
  let(:service) { described_class.new(cluster, user, params) }

  subject { service.execute(test_request) }

  describe '#execute' do
    before do
      allow(ClusterUpdateAppWorker).to receive(:perform_async)
    end

    context 'application is not installed' do
      it 'raises Clusters::Applications::BaseService::InvalidApplicationError' do
        expect(ClusterUpdateAppWorker).not_to receive(:perform_async)

        expect { subject }
          .to raise_exception { Clusters::Applications::BaseService::InvalidApplicationError }
          .and not_change { Clusters::Applications::Knative.count }
          .and not_change { Clusters::Applications::Knative.with_status(:scheduled).count }
      end
    end

    context 'application is installed' do
      context 'application is schedulable' do
        let!(:application) do
          create(:clusters_applications_knative, status: 3, cluster: cluster)
        end

        it 'updates the application data' do
          expect do
            subject
          end.to change { application.reload.hostname }.to(params[:hostname])
        end

        it 'makes application scheduled!' do
          subject

          expect(application.reload).to be_scheduled
        end

        it 'schedules ClusterUpdateAppWorker' do
          expect(ClusterUpdateAppWorker).to receive(:perform_async)

          subject
        end
      end

      context 'application is not schedulable' do
        let!(:application) do
          create(:clusters_applications_knative, status: 4, cluster: cluster)
        end

        it 'raises StateMachines::InvalidTransition' do
          expect(ClusterUpdateAppWorker).not_to receive(:perform_async)

          expect { subject }
            .to raise_exception { StateMachines::InvalidTransition }
            .and not_change { application.reload.hostname }
            .and not_change { Clusters::Applications::Knative.with_status(:scheduled).count }
        end
      end
    end
  end
end

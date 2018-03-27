require 'spec_helper'

describe Clusters::Applications::ScheduleInstallationService do
  def count_scheduled
    application_class&.with_status(:scheduled)&.count || 0
  end

  shared_examples 'a failing service' do
    it 'raise an exception' do
      expect(ClusterInstallAppWorker).not_to receive(:perform_async)
      count_before = count_scheduled

      expect { service.execute }.to raise_error(StandardError)
      expect(count_scheduled).to eq(count_before)
    end
  end

  describe '#execute' do
    let(:application_class) { Clusters::Applications::Helm }
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }
    let(:service) { described_class.new(project, nil, cluster: cluster, application_class: application_class) }

    it 'creates a new application' do
      allow(ClusterInstallAppWorker).to receive(:perform_async)

      expect { service.execute }.to change { application_class.count }.by(1)
    end

    it 'make the application scheduled' do
      expect(ClusterInstallAppWorker).to receive(:perform_async).with(application_class.application_name, kind_of(Numeric)).once

      expect { service.execute }.to change { application_class.with_status(:scheduled).count }.by(1)
    end

    context 'when installation is already in progress' do
      let(:application) { create(:clusters_applications_helm, :installing) }
      let(:cluster) { application.cluster }

      it_behaves_like 'a failing service'
    end

    context 'when application_class is nil' do
      let(:application_class) { nil }

      it_behaves_like 'a failing service'
    end

    context 'when application cannot be persisted' do
      before do
        expect_any_instance_of(application_class).to receive(:make_scheduled!).once.and_raise(ActiveRecord::RecordInvalid)
      end

      it_behaves_like 'a failing service'
    end
  end
end

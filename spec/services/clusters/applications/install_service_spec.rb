require 'spec_helper'

describe Clusters::Applications::InstallService do
  describe '#execute' do
    let(:application) { create(:cluster_applications_helm, :scheduled) }
    let(:service) { described_class.new(application) }

    context 'when there are no errors' do
      before do
        expect_any_instance_of(Gitlab::Kubernetes::Helm).to receive(:install).with(application)
        allow(ClusterWaitForAppInstallationWorker).to receive(:perform_in).and_return(nil)
      end

      it 'make the application installing' do
        service.execute

        expect(application).to be_installing
      end

      it 'schedule async installation status check' do
        expect(ClusterWaitForAppInstallationWorker).to receive(:perform_in).once

        service.execute
      end
    end

    context 'when k8s cluster communication fails' do
      before do
        error = KubeException.new(500, 'system failure', nil)
        expect_any_instance_of(Gitlab::Kubernetes::Helm).to receive(:install).with(application).and_raise(error)
      end

      it 'make the application errored' do
        service.execute

        expect(application).to be_errored
        expect(application.status_reason).to match(/kubernetes error:/i)
      end
    end

    context 'when application cannot be persisted' do
      let(:application) { build(:cluster_applications_helm, :scheduled) }

      it 'make the application errored' do
        expect(application).to receive(:make_installing!).once.and_raise(ActiveRecord::RecordInvalid)
        expect_any_instance_of(Gitlab::Kubernetes::Helm).not_to receive(:install)

        service.execute

        expect(application).to be_errored
      end
    end
  end
end

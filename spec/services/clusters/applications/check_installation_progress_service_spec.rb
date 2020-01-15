# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::CheckInstallationProgressService, '#execute' do
  RESCHEDULE_PHASES = Gitlab::Kubernetes::Pod::PHASES - [Gitlab::Kubernetes::Pod::SUCCEEDED, Gitlab::Kubernetes::Pod::FAILED].freeze

  let(:application) { create(:clusters_applications_helm, :installing) }
  let(:service) { described_class.new(application) }
  let(:phase) { Gitlab::Kubernetes::Pod::UNKNOWN }
  let(:errors) { nil }

  shared_examples 'a not yet terminated installation' do |a_phase|
    let(:phase) { a_phase }

    before do
      expect(service).to receive(:pod_phase).once.and_return(phase)
    end

    context "when phase is #{a_phase}" do
      context 'when not timed_out' do
        it 'reschedule a new check' do
          expect(ClusterWaitForAppInstallationWorker).to receive(:perform_in).once
          expect(service).not_to receive(:remove_installation_pod)

          expect do
            service.execute

            application.reload
          end.not_to change(application, :status)

          expect(application.status_reason).to be_nil
        end
      end
    end
  end

  shared_examples 'error handling' do
    context 'when installation raises a Kubeclient::HttpError' do
      let(:cluster) { create(:cluster, :provided_by_user, :project) }
      let(:logger) { service.send(:logger) }
      let(:error) { Kubeclient::HttpError.new(401, 'Unauthorized', nil) }

      before do
        application.update!(cluster: cluster)

        expect(service).to receive(:pod_phase).and_raise(error)
      end

      include_examples 'logs kubernetes errors' do
        let(:error_name) { 'Kubeclient::HttpError' }
        let(:error_message) { 'Unauthorized' }
        let(:error_code) { 401 }
      end

      it 'shows the response code from the error' do
        service.execute

        expect(application).to be_errored.or(be_update_errored)
        expect(application.status_reason).to eq('Kubernetes error: 401')
      end
    end
  end

  before do
    allow(service).to receive(:installation_errors).and_return(errors)
    allow(service).to receive(:remove_installation_pod).and_return(nil)
  end

  context 'when application is updating' do
    let(:application) { create(:clusters_applications_helm, :updating) }

    include_examples 'error handling'

    RESCHEDULE_PHASES.each { |phase| it_behaves_like 'a not yet terminated installation', phase }

    context 'when installation POD succeeded' do
      let(:phase) { Gitlab::Kubernetes::Pod::SUCCEEDED }

      before do
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'removes the installation POD' do
        expect(service).to receive(:remove_installation_pod).once

        service.execute
      end

      it 'make the application installed' do
        expect(ClusterWaitForAppInstallationWorker).not_to receive(:perform_in)

        service.execute

        expect(application).to be_updated
        expect(application.status_reason).to be_nil
      end
    end

    context 'when installation POD failed' do
      let(:phase) { Gitlab::Kubernetes::Pod::FAILED }
      let(:errors) { 'test installation failed' }

      before do
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'make the application errored' do
        service.execute

        expect(application).to be_update_errored
        expect(application.status_reason).to eq('Operation failed. Check pod logs for install-helm for more details.')
      end
    end

    context 'when timed out' do
      let(:application) { create(:clusters_applications_helm, :timed_out, :updating) }

      before do
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'make the application errored' do
        expect(ClusterWaitForAppInstallationWorker).not_to receive(:perform_in)

        service.execute

        expect(application).to be_update_errored
        expect(application.status_reason).to eq('Operation timed out. Check pod logs for install-helm for more details.')
      end
    end
  end

  context 'when application is installing' do
    include_examples 'error handling'

    RESCHEDULE_PHASES.each { |phase| it_behaves_like 'a not yet terminated installation', phase }

    context 'when installation POD succeeded' do
      let(:phase) { Gitlab::Kubernetes::Pod::SUCCEEDED }

      before do
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'removes the installation POD' do
        expect_next_instance_of(Gitlab::Kubernetes::Helm::Api) do |instance|
          expect(instance).to receive(:delete_pod!).with(kind_of(String)).once
        end
        expect(service).to receive(:remove_installation_pod).and_call_original

        service.execute
      end

      it 'make the application installed' do
        expect(ClusterWaitForAppInstallationWorker).not_to receive(:perform_in)

        service.execute

        expect(application).to be_installed
        expect(application.status_reason).to be_nil
      end

      it 'tracks application install' do
        expect(Gitlab::Tracking).to receive(:event).with('cluster:applications', "cluster_application_helm_installed")

        service.execute
      end
    end

    context 'when installation POD failed' do
      let(:phase) { Gitlab::Kubernetes::Pod::FAILED }
      let(:errors) { 'test installation failed' }

      before do
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'make the application errored' do
        service.execute

        expect(application).to be_errored
        expect(application.status_reason).to eq('Operation failed. Check pod logs for install-helm for more details.')
      end
    end

    context 'when timed out' do
      let(:application) { create(:clusters_applications_helm, :timed_out) }

      before do
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'make the application errored' do
        expect(ClusterWaitForAppInstallationWorker).not_to receive(:perform_in)

        service.execute

        expect(application).to be_errored
        expect(application.status_reason).to eq('Operation timed out. Check pod logs for install-helm for more details.')
      end
    end
  end
end

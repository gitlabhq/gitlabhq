# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::CheckUninstallProgressService do
  RESCHEDULE_PHASES = Gitlab::Kubernetes::Pod::PHASES - [Gitlab::Kubernetes::Pod::SUCCEEDED, Gitlab::Kubernetes::Pod::FAILED].freeze

  let(:application) { create(:clusters_applications_prometheus, :uninstalling) }
  let(:service) { described_class.new(application) }
  let(:phase) { Gitlab::Kubernetes::Pod::UNKNOWN }
  let(:errors) { nil }
  let(:worker_class) { Clusters::Applications::WaitForUninstallAppWorker }

  before do
    allow(service).to receive(:installation_errors).and_return(errors)
    allow(service).to receive(:remove_installation_pod)
  end

  shared_examples 'a not yet terminated installation' do |a_phase|
    let(:phase) { a_phase }

    before do
      expect(service).to receive(:pod_phase).once.and_return(phase)
    end

    context "when phase is #{a_phase}" do
      context 'when not timed_out' do
        it 'reschedule a new check' do
          expect(worker_class).to receive(:perform_in).once
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

  context 'when application is uninstalling' do
    RESCHEDULE_PHASES.each { |phase| it_behaves_like 'a not yet terminated installation', phase }

    context 'when installation POD succeeded' do
      let(:phase) { Gitlab::Kubernetes::Pod::SUCCEEDED }

      before do
        expect_any_instance_of(Gitlab::Kubernetes::Helm::Api)
            .to receive(:delete_pod!)
            .with(kind_of(String))
            .once
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'removes the installation POD' do
        expect(service).to receive(:remove_uninstallation_pod).and_call_original

        service.execute
      end

      it 'runs application post_uninstall' do
        expect(application).to receive(:post_uninstall).and_call_original

        service.execute
      end

      it 'destroys the application' do
        expect(worker_class).not_to receive(:perform_in)

        service.execute

        expect(application).to be_destroyed
      end

      context 'an error occurs while destroying' do
        before do
          expect(application).to receive(:destroy!).once.and_raise("destroy failed")
        end

        it 'still removes the installation POD' do
          expect(service).to receive(:remove_uninstallation_pod).and_call_original

          service.execute
        end

        it 'makes the application uninstall_errored' do
          service.execute

          expect(application).to be_uninstall_errored
          expect(application.status_reason).to eq('Application uninstalled but failed to destroy: destroy failed')
        end
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

        expect(application).to be_uninstall_errored
        expect(application.status_reason).to eq('Operation failed. Check pod logs for uninstall-prometheus for more details.')
      end
    end

    context 'when timed out' do
      let(:application) { create(:clusters_applications_prometheus, :timed_out, :uninstalling) }

      before do
        expect(service).to receive(:pod_phase).once.and_return(phase)
      end

      it 'make the application errored' do
        expect(worker_class).not_to receive(:perform_in)

        service.execute

        expect(application).to be_uninstall_errored
        expect(application.status_reason).to eq('Operation timed out. Check pod logs for uninstall-prometheus for more details.')
      end
    end

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

        expect(application).to be_uninstall_errored
        expect(application.status_reason).to eq('Kubernetes error: 401')
      end
    end
  end
end

require 'spec_helper'

describe Clusters::Applications::CheckInstallationProgressService do
  RESCHEDULE_PHASES = Gitlab::Kubernetes::Pod::PHASES - [Gitlab::Kubernetes::Pod::SUCCEEDED, Gitlab::Kubernetes::Pod::FAILED].freeze

  def mock_helm_api(phase, errors: nil)
    expect(service).to receive(:installation_phase).once.and_return(phase)
    expect(service).to receive(:installation_errors).once.and_return(errors) if errors.present?
  end

  shared_examples 'not yet completed phase' do |phase|
    context "when the installation POD phase is #{phase}" do
      before do
        mock_helm_api(phase)
      end

      context 'when not timeouted' do
        it 'reschedule a new check' do
          expect(ClusterWaitForAppInstallationWorker).to receive(:perform_in).once

          service.execute

          expect(application).to be_installing
          expect(application.status_reason).to be_nil
        end
      end

      context 'when timeouted' do
        let(:application) { create(:applications_helm, :timeouted) }

        it 'make the application errored' do
          expect(ClusterWaitForAppInstallationWorker).not_to receive(:perform_in)

          service.execute

          expect(application).to be_errored
          expect(application.status_reason).to match(/\btimeouted\b/)
        end
      end
    end
  end

  describe '#execute' do
    let(:application) { create(:applications_helm, :installing) }
    let(:service) { described_class.new(application) }

    context 'when installation POD succeeded' do
      it 'make the application installed' do
        mock_helm_api(Gitlab::Kubernetes::Pod::SUCCEEDED)
        expect(service).to receive(:finalize_installation).once

        service.execute

        expect(application).to be_installed
        expect(application.status_reason).to be_nil
      end
    end

    context 'when installation POD failed' do
      let(:error_message) { 'test installation failed' }

      it 'make the application errored' do
        mock_helm_api(Gitlab::Kubernetes::Pod::FAILED, errors: error_message)
        expect(service).to receive(:finalize_installation).once

        service.execute

        expect(application).to be_errored
        expect(application.status_reason).to eq(error_message)
      end
    end

    RESCHEDULE_PHASES.each { |phase| it_behaves_like 'not yet completed phase', phase }
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::InstallService do
  describe '#execute' do
    let(:application) { create(:clusters_applications_helm, :scheduled) }
    let!(:install_command) { application.install_command }
    let(:service) { described_class.new(application) }
    let(:helm_client) { instance_double(Gitlab::Kubernetes::Helm::API) }

    before do
      allow(service).to receive(:install_command).and_return(install_command)
      allow(service).to receive(:helm_api).and_return(helm_client)
    end

    context 'when there are no errors' do
      before do
        expect(helm_client).to receive(:install).with(install_command)
        allow(ClusterWaitForAppInstallationWorker).to receive(:perform_in).and_return(nil)
      end

      it 'make the application installing' do
        expect(application.cluster).not_to be_nil
        service.execute

        expect(application).to be_installing
      end

      it 'schedule async installation status check' do
        expect(ClusterWaitForAppInstallationWorker).to receive(:perform_in).once

        service.execute
      end
    end

    context 'when k8s cluster communication fails' do
      let(:error) { Kubeclient::HttpError.new(500, 'system failure', nil) }

      before do
        expect(helm_client).to receive(:install).with(install_command).and_raise(error)
      end

      include_examples 'logs kubernetes errors' do
        let(:error_name) { 'Kubeclient::HttpError' }
        let(:error_message) { 'system failure' }
        let(:error_code) { 500 }
      end

      it 'make the application errored' do
        service.execute

        expect(application).to be_errored
        expect(application.status_reason).to match('Kubernetes error: 500')
      end
    end

    context 'a non kubernetes error happens' do
      let(:application) { create(:clusters_applications_helm, :scheduled) }
      let(:error) { StandardError.new('something bad happened') }

      before do
        expect(helm_client).to receive(:install).with(install_command).and_raise(error)
      end

      include_examples 'logs kubernetes errors' do
        let(:error_name) { 'StandardError' }
        let(:error_message) { 'something bad happened' }
        let(:error_code) { nil }
      end

      it 'make the application errored' do
        service.execute

        expect(application).to be_errored
        expect(application.status_reason).to eq('Failed to install.')
      end
    end
  end
end

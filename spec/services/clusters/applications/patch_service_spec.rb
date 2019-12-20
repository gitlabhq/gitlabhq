# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::PatchService do
  describe '#execute' do
    let(:application) { create(:clusters_applications_knative, :scheduled) }
    let!(:update_command) { application.update_command }
    let(:service) { described_class.new(application) }
    let(:helm_client) { instance_double(Gitlab::Kubernetes::Helm::Api) }

    before do
      allow(service).to receive(:update_command).and_return(update_command)
      allow(service).to receive(:helm_api).and_return(helm_client)
    end

    context 'when there are no errors' do
      before do
        expect(helm_client).to receive(:update).with(update_command)
        allow(ClusterWaitForAppInstallationWorker).to receive(:perform_in).and_return(nil)
      end

      it 'make the application updating' do
        expect(application.cluster).not_to be_nil
        service.execute

        expect(application).to be_updating
      end

      it 'schedule async installation status check' do
        expect(ClusterWaitForAppInstallationWorker).to receive(:perform_in).once

        service.execute
      end
    end

    context 'when kubernetes cluster communication fails' do
      let(:error) { Kubeclient::HttpError.new(500, 'system failure', nil) }

      before do
        expect(helm_client).to receive(:update).with(update_command).and_raise(error)
      end

      include_examples 'logs kubernetes errors' do
        let(:error_name) { 'Kubeclient::HttpError' }
        let(:error_message) { 'system failure' }
        let(:error_code) { 500 }
      end

      it 'make the application errored' do
        service.execute

        expect(application).to be_update_errored
        expect(application.status_reason).to eq(_('Kubernetes error: %{error_code}') % { error_code: 500 })
      end
    end

    context 'a non kubernetes error happens' do
      let(:application) { create(:clusters_applications_knative, :scheduled) }
      let(:error) { StandardError.new('something bad happened') }

      include_examples 'logs kubernetes errors' do
        let(:error_name) { 'StandardError' }
        let(:error_message) { 'something bad happened' }
        let(:error_code) { nil }
      end

      before do
        expect(helm_client).to receive(:update).with(update_command).and_raise(error)
      end

      it 'make the application errored' do
        service.execute

        expect(application).to be_update_errored
        expect(application.status_reason).to eq(_('Failed to update.'))
      end
    end
  end
end

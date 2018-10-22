# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::CreateService do
  include TestRequestHelpers

  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:user) { create(:user) }
  let(:params) { { application: 'helm' } }
  let(:service) { described_class.new(cluster, user, params) }

  describe '#execute' do
    before do
      allow(ClusterInstallAppWorker).to receive(:perform_async)
    end

    subject { service.execute(test_request) }

    it 'creates an application' do
      expect do
        subject

        cluster.reload
      end.to change(cluster, :application_helm)
    end

    it 'schedules an install via worker' do
      expect(ClusterInstallAppWorker).to receive(:perform_async).with('helm', anything).once

      subject
    end

    context 'jupyter application' do
      let(:params) do
        {
          application: 'jupyter',
          hostname: 'example.com'
        }
      end

      before do
        allow_any_instance_of(Clusters::Applications::ScheduleInstallationService).to receive(:execute)
      end

      it 'creates the application' do
        expect do
          subject

          cluster.reload
        end.to change(cluster, :application_jupyter)
      end

      it 'sets the hostname' do
        expect(subject.hostname).to eq('example.com')
      end

      it 'sets the oauth_application' do
        expect(subject.oauth_application).to be_present
      end
    end

    context 'invalid application' do
      let(:params) { { application: 'non-existent' } }

      it 'raises an error' do
        expect { subject }.to raise_error(Clusters::Applications::CreateService::InvalidApplicationError)
      end
    end
  end
end

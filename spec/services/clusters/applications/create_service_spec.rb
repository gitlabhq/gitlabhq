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
      allow(ClusterUpgradeAppWorker).to receive(:perform_async)
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

    context 'application already installed' do
      let!(:application) { create(:clusters_applications_helm, :installed, cluster: cluster) }

      it 'does not create a new application' do
        expect do
          subject
        end.not_to change(Clusters::Applications::Helm, :count)
      end

      it 'schedules an upgrade for the application' do
        expect(Clusters::Applications::ScheduleInstallationService).to receive(:new).with(application).and_call_original

        subject
      end
    end

    context 'cert manager application' do
      let(:params) do
        {
          application: 'cert_manager',
          email: 'test@example.com'
        }
      end

      before do
        allow_any_instance_of(Clusters::Applications::ScheduleInstallationService).to receive(:execute)
      end

      it 'creates the application' do
        expect do
          subject

          cluster.reload
        end.to change(cluster, :application_cert_manager)
      end

      it 'sets the email' do
        expect(subject.email).to eq('test@example.com')
      end
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

    context 'knative application' do
      let(:params) do
        {
          application: 'knative',
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
        end.to change(cluster, :application_knative)
      end

      it 'sets the hostname' do
        expect(subject.hostname).to eq('example.com')
      end
    end

    context 'invalid application' do
      let(:params) { { application: 'non-existent' } }

      it 'raises an error' do
        expect { subject }.to raise_error(Clusters::Applications::CreateService::InvalidApplicationError)
      end
    end

    context 'group cluster' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :group) }

      using RSpec::Parameterized::TableSyntax

      before do
        allow_any_instance_of(Clusters::Applications::ScheduleInstallationService).to receive(:execute)
      end

      where(:application, :association, :allowed) do
        'helm'       | :application_helm       | true
        'ingress'    | :application_ingress    | true
        'runner'     | :application_runner     | false
        'jupyter'    | :application_jupyter    | false
        'prometheus' | :application_prometheus | false
      end

      with_them do
        let(:params) { { application: application } }

        it 'executes for each application' do
          if allowed
            expect do
              subject

              cluster.reload
            end.to change(cluster, association)
          else
            expect { subject }.to raise_error(Clusters::Applications::CreateService::InvalidApplicationError)
          end
        end
      end
    end
  end
end

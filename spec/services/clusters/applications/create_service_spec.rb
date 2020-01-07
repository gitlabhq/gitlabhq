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

    context 'application already installed' do
      let!(:application) { create(:clusters_applications_helm, :installed, cluster: cluster) }

      it 'does not create a new application' do
        expect do
          subject
        end.not_to change(Clusters::Applications::Helm, :count)
      end

      it 'schedules an upgrade for the application' do
        expect(ClusterUpgradeAppWorker).to receive(:perform_async)

        subject
      end
    end

    context 'known applications' do
      before do
        create(:clusters_applications_helm, :installed, cluster: cluster)
      end

      context 'ingress application' do
        let(:params) do
          {
            application: 'ingress',
            modsecurity_enabled: true
          }
        end

        before do
          expect_any_instance_of(Clusters::Applications::Ingress)
            .to receive(:make_scheduled!)
            .and_call_original
        end

        it 'creates the application' do
          expect do
            subject

            cluster.reload
          end.to change(cluster, :application_ingress)
        end

        it 'sets modsecurity_enabled' do
          expect(subject.modsecurity_enabled).to eq(true)
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
          expect_any_instance_of(Clusters::Applications::CertManager)
            .to receive(:make_scheduled!)
            .and_call_original
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
          create(:clusters_applications_ingress, :installed, external_ip: "127.0.0.0", cluster: cluster)
          expect_any_instance_of(Clusters::Applications::Jupyter)
            .to receive(:make_scheduled!)
            .and_call_original
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
          expect_any_instance_of(Clusters::Applications::Knative)
            .to receive(:make_scheduled!)
            .and_call_original
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

      context 'elastic stack application' do
        let(:params) do
          {
            application: 'elastic_stack',
            kibana_hostname: 'example.com'
          }
        end

        before do
          create(:clusters_applications_ingress, :installed, external_ip: "127.0.0.0", cluster: cluster)
          expect_any_instance_of(Clusters::Applications::ElasticStack)
            .to receive(:make_scheduled!)
            .and_call_original
        end

        it 'creates the application' do
          expect do
            subject

            cluster.reload
          end.to change(cluster, :application_elastic_stack)
        end

        it 'sets the kibana_hostname' do
          expect(subject.kibana_hostname).to eq('example.com')
        end
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

      where(:application, :association, :allowed, :pre_create_helm, :pre_create_ingress) do
        'helm'       | :application_helm       | true | false | false
        'ingress'    | :application_ingress    | true | true | false
        'runner'     | :application_runner     | true | true | false
        'prometheus' | :application_prometheus | true | true | false
        'jupyter'    | :application_jupyter    | true | true | true
      end

      with_them do
        before do
          klass = "Clusters::Applications::#{application.titleize}"
          allow_any_instance_of(klass.constantize).to receive(:make_scheduled!).and_call_original
          create(:clusters_applications_helm, :installed, cluster: cluster) if pre_create_helm
          create(:clusters_applications_ingress, :installed, cluster: cluster, external_hostname: 'example.com') if pre_create_ingress
        end

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

    context 'when application is installable' do
      shared_examples 'installable applications' do
        it 'makes the application scheduled' do
          expect do
            subject
          end.to change { Clusters::Applications::Helm.with_status(:scheduled).count }.by(1)
        end

        it 'schedules an install via worker' do
          expect(ClusterInstallAppWorker)
            .to receive(:perform_async)
            .with(*worker_arguments)
            .once

          subject
        end
      end

      context 'when application is associated with a cluster' do
        let(:application) { create(:clusters_applications_helm, :installable, cluster: cluster) }
        let(:worker_arguments) { [application.name, application.id] }

        it_behaves_like 'installable applications'
      end

      context 'when application is not associated with a cluster' do
        let(:worker_arguments) { [params[:application], kind_of(Numeric)] }

        it_behaves_like 'installable applications'
      end
    end

    context 'when installation is already in progress' do
      let!(:application) { create(:clusters_applications_helm, :installing, cluster: cluster) }

      it 'raises an exception' do
        expect { subject }
          .to raise_exception(StateMachines::InvalidTransition)
          .and not_change(application.class.with_status(:scheduled), :count)
      end

      it 'does not schedule a cluster worker' do
        expect(ClusterInstallAppWorker).not_to receive(:perform_async)
      end
    end

    context 'when application is installed' do
      %i(installed updated).each do |status|
        let(:application) { create(:clusters_applications_helm, status, cluster: cluster) }

        it 'schedules an upgrade via worker' do
          expect(ClusterUpgradeAppWorker)
            .to receive(:perform_async)
            .with(application.name, application.id)
            .once

          subject

          expect(application.reload).to be_scheduled
        end
      end
    end
  end
end

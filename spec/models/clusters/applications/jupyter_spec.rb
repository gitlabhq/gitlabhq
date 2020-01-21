# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Jupyter do
  include_examples 'cluster application core specs', :clusters_applications_jupyter
  include_examples 'cluster application status specs', :clusters_applications_jupyter
  include_examples 'cluster application version specs', :clusters_applications_jupyter
  include_examples 'cluster application helm specs', :clusters_applications_jupyter

  it { is_expected.to belong_to(:oauth_application) }

  describe '#can_uninstall?' do
    let(:ingress) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }
    let(:jupyter) { create(:clusters_applications_jupyter, cluster: ingress.cluster) }

    subject { jupyter.can_uninstall? }

    it { is_expected.to be_truthy }
  end

  describe '#set_initial_status' do
    before do
      jupyter.set_initial_status
    end

    context 'when ingress is not installed' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }
      let(:jupyter) { create(:clusters_applications_jupyter, cluster: cluster) }

      it { expect(jupyter).to be_not_installable }
    end

    context 'when ingress is installed and external_ip is assigned' do
      let(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
      let(:jupyter) { create(:clusters_applications_jupyter, cluster: ingress.cluster) }

      it { expect(jupyter).to be_installable }
    end

    context 'when ingress is installed and external_hostname is assigned' do
      let(:ingress) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }
      let(:jupyter) { create(:clusters_applications_jupyter, cluster: ingress.cluster) }

      it { expect(jupyter).to be_installable }
    end
  end

  describe '#install_command' do
    let!(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
    let!(:jupyter) { create(:clusters_applications_jupyter, cluster: ingress.cluster) }

    subject { jupyter.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with 4 arguments' do
      expect(subject.name).to eq('jupyter')
      expect(subject.chart).to eq('jupyter/jupyterhub')
      expect(subject.version).to eq('0.9.0-beta.2')

      expect(subject).to be_rbac
      expect(subject.repository).to eq('https://jupyterhub.github.io/helm-chart/')
      expect(subject.files).to eq(jupyter.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        jupyter.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:jupyter) { create(:clusters_applications_jupyter, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('0.9.0-beta.2')
      end
    end
  end

  describe '#files' do
    let(:cluster) { create(:cluster, :with_installed_helm, :provided_by_gcp, :project) }
    let(:application) { create(:clusters_applications_jupyter, cluster: cluster) }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    context 'when cluster belongs to a project' do
      it 'includes valid values' do
        expect(values).to include('ingress')
        expect(values).to include('hub')
        expect(values).to include('proxy')
        expect(values).to include('auth')
        expect(values).to include('singleuser')
        expect(values).to match(/clientId: '?#{application.oauth_application.uid}/)
        expect(values).to match(/callbackUrl: '?#{application.callback_url}/)
        expect(values).to include("gitlabProjectIdWhitelist:\n    - #{application.cluster.project.id}")
        expect(values).to include("c.GitLabOAuthenticator.scope = ['api read_repository write_repository']")
        expect(values).to match(/GITLAB_HOST: '?#{Gitlab.config.gitlab.host}/)
        expect(values).to match(/GITLAB_CLUSTER_ID: '?#{application.cluster.id}/)
      end
    end

    context 'when cluster belongs to a group' do
      let(:group) { create(:group) }
      let(:cluster) { create(:cluster, :with_installed_helm, :provided_by_gcp, :group, groups: [group]) }

      it 'includes valid values' do
        expect(values).to include('ingress')
        expect(values).to include('hub')
        expect(values).to include('proxy')
        expect(values).to include('auth')
        expect(values).to include('singleuser')
        expect(values).to match(/clientId: '?#{application.oauth_application.uid}/)
        expect(values).to match(/callbackUrl: '?#{application.callback_url}/)
        expect(values).to include("gitlabGroupWhitelist:\n    - #{group.to_param}")
        expect(values).to include("c.GitLabOAuthenticator.scope = ['api read_repository write_repository']")
        expect(values).to match(/GITLAB_HOST: '?#{Gitlab.config.gitlab.host}/)
        expect(values).to match(/GITLAB_CLUSTER_ID: '?#{application.cluster.id}/)
      end
    end
  end
end

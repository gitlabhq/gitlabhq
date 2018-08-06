require 'rails_helper'

describe Clusters::Applications::Jupyter do
  include_examples 'cluster application core specs', :clusters_applications_jupyter

  it { is_expected.to belong_to(:oauth_application) }

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
  end

  describe '#make_installing!' do
    before do
      application.make_installing!
    end

    context 'application install previously errored with older version' do
      let(:application) { create(:clusters_applications_jupyter, :scheduled, version: 'v0.5') }

      it 'updates the application version' do
        expect(application.reload.version).to eq('v0.6')
      end
    end
  end

  describe '#install_command' do
    let!(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
    let!(:jupyter) { create(:clusters_applications_jupyter, cluster: ingress.cluster) }

    subject { jupyter.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with 4 arguments' do
      expect(subject.name).to eq('jupyter')
      expect(subject.chart).to eq('jupyter/jupyterhub')
      expect(subject.version).to eq('v0.6')
      expect(subject.repository).to eq('https://jupyterhub.github.io/helm-chart/')
      expect(subject.values).to eq(jupyter.values)
    end

    context 'application failed to install previously' do
      let(:jupyter) { create(:clusters_applications_jupyter, :errored, version: '0.0.1') }

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('v0.6')
      end
    end
  end

  describe '#values' do
    let(:jupyter) { create(:clusters_applications_jupyter) }

    subject { jupyter.values }

    it 'should include valid values' do
      is_expected.to include('ingress')
      is_expected.to include('hub')
      is_expected.to include('rbac')
      is_expected.to include('proxy')
      is_expected.to include('auth')
      is_expected.to include("clientId: #{jupyter.oauth_application.uid}")
      is_expected.to include("callbackUrl: #{jupyter.callback_url}")
    end
  end
end

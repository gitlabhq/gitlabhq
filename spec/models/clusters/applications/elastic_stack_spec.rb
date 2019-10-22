# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::ElasticStack do
  include_examples 'cluster application core specs', :clusters_applications_elastic_stack
  include_examples 'cluster application status specs', :clusters_applications_elastic_stack
  include_examples 'cluster application version specs', :clusters_applications_elastic_stack
  include_examples 'cluster application helm specs', :clusters_applications_elastic_stack

  describe '#can_uninstall?' do
    let(:ingress) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }
    let(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: ingress.cluster) }

    subject { elastic_stack.can_uninstall? }

    it { is_expected.to be_truthy }
  end

  describe '#set_initial_status' do
    before do
      elastic_stack.set_initial_status
    end

    context 'when ingress is not installed' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }
      let(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: cluster) }

      it { expect(elastic_stack).to be_not_installable }
    end

    context 'when ingress is installed and external_ip is assigned' do
      let(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
      let(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: ingress.cluster) }

      it { expect(elastic_stack).to be_installable }
    end

    context 'when ingress is installed and external_hostname is assigned' do
      let(:ingress) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }
      let(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: ingress.cluster) }

      it { expect(elastic_stack).to be_installable }
    end
  end

  describe '#install_command' do
    let!(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
    let!(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: ingress.cluster) }

    subject { elastic_stack.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with elastic stack arguments' do
      expect(subject.name).to eq('elastic-stack')
      expect(subject.chart).to eq('stable/elastic-stack')
      expect(subject.version).to eq('1.8.0')
      expect(subject).to be_rbac
      expect(subject.files).to eq(elastic_stack.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        elastic_stack.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:elastic_stack) { create(:clusters_applications_elastic_stack, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('1.8.0')
      end
    end
  end

  describe '#uninstall_command' do
    let!(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
    let!(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: ingress.cluster) }

    subject { elastic_stack.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::DeleteCommand) }

    it 'is initialized with elastic stack arguments' do
      expect(subject.name).to eq('elastic-stack')
      expect(subject).to be_rbac
      expect(subject.files).to eq(elastic_stack.files)
    end

    it 'specifies a post delete command to remove custom resource definitions' do
      expect(subject.postdelete).to eq([
        'kubectl delete pvc --selector release\\=elastic-stack'
      ])
    end
  end

  describe '#files' do
    let!(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
    let!(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: ingress.cluster) }

    let(:values) { subject[:'values.yaml'] }

    subject { elastic_stack.files }

    it 'includes elastic stack specific keys in the values.yaml file' do
      expect(values).to include('ELASTICSEARCH_HOSTS')
    end
  end
end

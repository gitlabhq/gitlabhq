# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes::ConfigureService do
  let(:platform) { create(:cluster_platform_kubernetes) }
  let(:kubeclient) { platform.kubeclient }

  let(:service) { described_class.new(platform) }

  describe '#execute' do
    subject { service.execute }

    context 'no project' do
      it 'does nothing' do
        subject
      end
    end

    context 'cluster with a project' do
      let(:project) { create(:project, name: 'hello') }

      before do
        platform.cluster.projects << project

        allow(kubeclient).to receive(:get_namespace).and_return(nil)
        allow(kubeclient).to receive(:create_namespace).and_return(nil)
      end

      it 'creates a kubernetes namespace' do
        expect(kubeclient).to receive(:get_namespace).once.ordered
        expect(kubeclient).to receive(:create_namespace).once.ordered

        subject
      end

      it 'persists the namespace' do
        expect do
          subject

          project.cluster_project.reload
        end.to change(project.cluster_project, :namespace)

        expect(project.cluster_project.namespace).to eq "hello-#{project.id}"
      end
    end

    context 'platform has namespace' do
      let(:platform) { create(:cluster_platform_kubernetes, namespace: 'my-namespace') }
      let(:project) { create(:project, name: 'hello') }

      before do
        platform.cluster.projects << project

        allow(kubeclient).to receive(:get_namespace).and_return(nil)
        allow(kubeclient).to receive(:create_namespace).and_return(nil)
      end

      it 'creates a kubernetes namespace' do
        expect(kubeclient).to receive(:get_namespace).once.ordered
        expect(kubeclient).to receive(:create_namespace).once.ordered

        subject
      end

      it 'persists the namespace' do
        expect do
          subject

          project.cluster_project.reload
        end.to change(project.cluster_project, :namespace)

        expect(project.cluster_project.namespace).to eq 'my-namespace'
      end
    end
  end
end

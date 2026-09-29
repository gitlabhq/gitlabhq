# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentClusterEntity do
  describe '#as_json' do
    subject { described_class.new(deployment, request: request).as_json }

    let_it_be(:maintainer) { create(:user) }
    let_it_be(:reporter) { create(:user) }
    let_it_be(:project) { create(:project, maintainers: maintainer, reporters: reporter) }
    let_it_be(:cluster) { create(:cluster, name: 'the-cluster', projects: [project]) }

    let(:current_user) { maintainer }
    let(:request) { double(:request, current_user: current_user) }
    let(:deployment_cluster) { build_stubbed(:deployment_cluster, cluster: cluster) }
    let(:deployment) { build_stubbed(:deployment, deployment_cluster: deployment_cluster) }

    it 'matches deployment_cluster entity schema' do
      expect(subject.as_json).to match_schema('deployment_cluster')
    end

    it 'exposes the cluster details' do
      expect(subject[:name]).to eq('the-cluster')
      expect(subject[:path]).to eq("/#{project.full_path}/-/clusters/#{cluster.id}")
      expect(subject[:kubernetes_namespace]).to eq(deployment_cluster.kubernetes_namespace)
    end

    context 'when the user does not have permission to view the cluster' do
      let(:current_user) { reporter }

      it 'does not include the path nor the namespace' do
        expect(subject[:path]).to be_nil
        expect(subject[:kubernetes_namespace]).to be_nil
      end
    end
  end
end

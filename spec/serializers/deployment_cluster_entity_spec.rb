# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentClusterEntity do
  describe '#as_json' do
    subject { described_class.new(deployment, request: request).as_json }

    let(:maintainer) { create(:user) }
    let(:reporter) { create(:user) }
    let(:current_user) { maintainer }
    let(:request) { double(:request, current_user: current_user) }
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, name: 'the-cluster', projects: [project]) }
    let(:deployment) { create(:deployment) }
    let!(:deployment_cluster) { create(:deployment_cluster, cluster: cluster, deployment: deployment) }

    before do
      project.add_maintainer(maintainer)
      project.add_reporter(reporter)
    end

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

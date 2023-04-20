# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::CreateService, feature_category: :deployment_management do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(user, params).execute(access_token: access_token) }

  context 'when provider is gcp' do
    context 'when project has no clusters' do
      context 'when correct params' do
        let(:params) do
          {
            name: 'test-cluster',
            provider_type: :gcp,
            provider_gcp_attributes: {
              gcp_project_id: 'gcp-project',
              zone: 'us-central1-a',
              num_nodes: 1,
              machine_type: 'machine_type-a',
              legacy_abac: 'true'
            },
            clusterable: project
          }
        end

        include_examples 'create cluster service success'
      end

      context 'when invalid params' do
        let(:params) do
          {
            name: 'test-cluster',
            provider_type: :gcp,
            provider_gcp_attributes: {
              gcp_project_id: '!!!!!!!',
              zone: 'us-central1-a',
              num_nodes: 1,
              machine_type: 'machine_type-a'
            },
            clusterable: project
          }
        end

        include_examples 'create cluster service error'
      end
    end

    context 'when project has a cluster' do
      include_context 'with valid cluster create params'
      let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

      it 'creates another cluster' do
        expect { subject }.to change { Clusters::Cluster.count }.by(1)
      end
    end
  end

  context 'when another cluster exists' do
    let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

    context 'when correct params' do
      let(:params) do
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a',
            legacy_abac: 'true'
          },
          clusterable: project
        }
      end

      include_examples 'create cluster service success'
    end

    context 'when invalid params' do
      let(:params) do
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: '!!!!!!!',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          },
          clusterable: project
        }
      end

      include_examples 'create cluster service error'
    end
  end

  context 'when params includes :management_project_id' do
    subject(:cluster) { described_class.new(user, params).execute(access_token: access_token) }

    let(:params) do
      {
        name: 'test-cluster',
        provider_type: :gcp,
        provider_gcp_attributes: {
          gcp_project_id: 'gcp-project',
          zone: 'us-central1-a',
          num_nodes: 1,
          machine_type: 'machine_type-a',
          legacy_abac: 'true'
        },
        clusterable: clusterable,
        management_project_id: management_project_id
      }
    end

    let(:clusterable) { project }
    let(:management_project_id) { management_project.id }
    let(:management_project_namespace) { project.namespace }
    let(:management_project) { create(:project, namespace: management_project_namespace) }

    shared_examples 'invalid project or cluster permissions' do
      it 'does not persist the cluster and adds errors' do
        expect(cluster).not_to be_persisted

        expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')
      end
    end

    shared_examples 'setting a management project' do
      context 'when user is authorized to adminster manangement_project' do
        before do
          management_project.add_maintainer(user)
        end

        it 'persists the cluster' do
          expect(cluster).to be_persisted

          expect(cluster.management_project).to eq(management_project)
        end
      end

      context 'when user is not authorized to adminster manangement_project' do
        include_examples 'invalid project or cluster permissions'
      end
    end

    shared_examples 'setting a management project outside of scope' do
      context 'when manangement_project is outside of the namespace scope' do
        let(:management_project_namespace) { create(:group) }

        it 'does not persist the cluster' do
          expect(cluster).not_to be_persisted

          expect(cluster.errors[:management_project_id]).to include('Project does not exist or you don\'t have permission to perform this action')
        end
      end
    end

    context 'management_project is non-existent' do
      let(:management_project_id) { 0 }

      include_examples 'invalid project or cluster permissions'
    end

    context 'project cluster' do
      include_examples 'setting a management project'
      include_examples 'setting a management project outside of scope'
    end

    context 'group cluster' do
      let(:management_project_namespace) { create(:group) }
      let(:clusterable) { management_project_namespace }

      include_examples 'setting a management project'
      include_examples 'setting a management project outside of scope'
    end

    context 'instance cluster' do
      let(:clusterable) { Clusters::Instance.new }

      include_examples 'setting a management project'
    end
  end
end

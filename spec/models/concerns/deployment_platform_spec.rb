# frozen_string_literal: true

require 'spec_helper'

describe DeploymentPlatform do
  let(:project) { create(:project) }

  describe '#deployment_platform' do
    subject { project.deployment_platform }

    context 'with no Kubernetes configuration on CI/CD, no Kubernetes Service' do
      it { is_expected.to be_nil }
    end

    context 'when project is the cluster\'s management project ' do
      let!(:cluster_with_management_project) { create(:cluster, :provided_by_user, management_project: project) }

      context 'cluster_management_project feature is enabled' do
        it 'returns the cluster with management project' do
          is_expected.to eq(cluster_with_management_project.platform_kubernetes)
        end
      end

      context 'cluster_management_project feature is disabled' do
        before do
          stub_feature_flags(cluster_management_project: false)
        end

        it 'returns nothing' do
          is_expected.to be_nil
        end
      end
    end

    context 'when project has configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:platform_kubernetes) { cluster.platform_kubernetes }

      it 'returns the Kubernetes platform' do
        expect(subject).to eq(platform_kubernetes)
      end

      context 'with a group level kubernetes cluster' do
        let(:group_cluster) { create(:cluster, :provided_by_gcp, :group) }

        before do
          project.update!(group: group_cluster.group)
        end

        it 'returns the Kubernetes platform from the project cluster' do
          expect(subject).to eq(platform_kubernetes)
        end
      end
    end

    context 'when group has configured kubernetes cluster' do
      let!(:group_cluster) { create(:cluster, :provided_by_gcp, :group) }
      let(:group) { group_cluster.group }

      before do
        project.update!(group: group)
      end

      it 'returns the Kubernetes platform' do
        is_expected.to eq(group_cluster.platform_kubernetes)
      end

      context 'when project is the cluster\'s management project ' do
        let!(:cluster_with_management_project) { create(:cluster, :provided_by_user, management_project: project) }

        context 'cluster_management_project feature is enabled' do
          it 'returns the cluster with management project' do
            is_expected.to eq(cluster_with_management_project.platform_kubernetes)
          end
        end

        context 'cluster_management_project feature is disabled' do
          before do
            stub_feature_flags(cluster_management_project: false)
          end

          it 'returns the group cluster' do
            is_expected.to eq(group_cluster.platform_kubernetes)
          end
        end
      end

      context 'when project is not the cluster\'s management project' do
        let(:another_project) { create(:project, group: group) }
        let!(:cluster_with_management_project) { create(:cluster, :provided_by_user, management_project: another_project) }

        it 'returns the group cluster' do
          is_expected.to eq(group_cluster.platform_kubernetes)
        end
      end

      context 'when child group has configured kubernetes cluster' do
        let(:child_group1) { create(:group, parent: group) }
        let!(:child_group1_cluster) { create(:cluster_for_group, groups: [child_group1]) }

        before do
          project.update!(group: child_group1)
        end

        it 'returns the Kubernetes platform for the child group' do
          is_expected.to eq(child_group1_cluster.platform_kubernetes)
        end

        context 'deeply nested group' do
          let(:child_group2) { create(:group, parent: child_group1) }
          let!(:child_group2_cluster) { create(:cluster_for_group, groups: [child_group2]) }

          before do
            project.update!(group: child_group2)
          end

          it 'returns most nested group cluster Kubernetes platform' do
            is_expected.to eq(child_group2_cluster.platform_kubernetes)
          end

          context 'cluster in the middle of hierarchy is disabled' do
            before do
              child_group2_cluster.update!(enabled: false)
            end

            it 'returns closest enabled Kubenetes platform' do
              is_expected.to eq(child_group1_cluster.platform_kubernetes)
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentPlatform do
  let(:project) { create(:project) }

  describe '#deployment_platform' do
    subject { project.deployment_platform }

    context 'multiple clusters' do
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }

      shared_examples 'certificate_based_clusters is disabled' do
        before do
          stub_feature_flags(certificate_based_clusters: false)
        end

        it { is_expected.to be_nil }
      end

      shared_examples 'matching environment scope' do
        it 'returns environment specific cluster' do
          is_expected.to eq(cluster.platform_kubernetes)
        end

        it_behaves_like 'certificate_based_clusters is disabled'
      end

      shared_examples 'not matching environment scope' do
        it 'returns default cluster' do
          is_expected.to eq(default_cluster.platform_kubernetes)
        end

        it_behaves_like 'certificate_based_clusters is disabled'
      end

      context 'multiple clusters use the same management project' do
        let(:management_project) { create(:project, group: group) }

        let!(:default_cluster) do
          create(:cluster_for_group, groups: [group], environment_scope: '*', management_project: management_project)
        end

        let!(:cluster) do
          create(:cluster_for_group, groups: [group], environment_scope: 'review/*', management_project: management_project)
        end

        let(:environment) { 'review/name' }

        subject { management_project.deployment_platform(environment: environment) }

        it_behaves_like 'matching environment scope'
      end

      context 'when project does not have a cluster but has group clusters' do
        let!(:default_cluster) do
          create(
            :cluster,
            :provided_by_user,
            cluster_type: :group_type,
            groups: [group],
            environment_scope: '*'
          )
        end

        let!(:cluster) do
          create(
            :cluster,
            :provided_by_user,
            cluster_type: :group_type,
            environment_scope: 'review/*',
            groups: [group]
          )
        end

        let(:environment) { 'review/name' }

        subject { project.deployment_platform(environment: environment) }

        context 'when environment scope is exactly matched' do
          before do
            cluster.update!(environment_scope: 'review/name')
          end

          it_behaves_like 'matching environment scope'
        end

        context 'when environment scope is matched by wildcard' do
          before do
            cluster.update!(environment_scope: 'review/*')
          end

          it_behaves_like 'matching environment scope'
        end

        context 'when environment scope does not match' do
          before do
            cluster.update!(environment_scope: 'review/*/special')
          end

          it_behaves_like 'not matching environment scope'
        end

        context 'when group belongs to a parent group' do
          let(:parent_group) { create(:group) }
          let(:group) { create(:group, parent: parent_group) }

          context 'when parent_group has a cluster with default scope' do
            let!(:parent_group_cluster) do
              create(
                :cluster,
                :provided_by_user,
                cluster_type: :group_type,
                environment_scope: '*',
                groups: [parent_group]
              )
            end

            it_behaves_like 'matching environment scope'
          end

          context 'when parent_group has a cluster that is an exact match' do
            let!(:parent_group_cluster) do
              create(
                :cluster,
                :provided_by_user,
                cluster_type: :group_type,
                environment_scope: 'review/name',
                groups: [parent_group]
              )
            end

            it_behaves_like 'matching environment scope'
          end
        end
      end

      context 'with instance clusters' do
        let!(:default_cluster) do
          create(:cluster, :provided_by_user, :instance, environment_scope: '*')
        end

        let!(:cluster) do
          create(:cluster, :provided_by_user, :instance, environment_scope: 'review/*')
        end

        let(:environment) { 'review/name' }

        subject { project.deployment_platform(environment: environment) }

        context 'when environment scope is exactly matched' do
          before do
            cluster.update!(environment_scope: 'review/name')
          end

          it_behaves_like 'matching environment scope'
        end

        context 'when environment scope is matched by wildcard' do
          before do
            cluster.update!(environment_scope: 'review/*')
          end

          it_behaves_like 'matching environment scope'
        end

        context 'when environment scope does not match' do
          before do
            cluster.update!(environment_scope: 'review/*/special')
          end

          it_behaves_like 'not matching environment scope'
        end
      end

      context 'when environment is specified' do
        let!(:default_cluster) { create(:cluster, :provided_by_user, projects: [project], environment_scope: '*') }
        let!(:cluster) { create(:cluster, :provided_by_user, environment_scope: 'review/*', projects: [project]) }

        let!(:group_default_cluster) do
          create(
            :cluster,
            :provided_by_user,
            cluster_type: :group_type,
            groups: [group],
            environment_scope: '*'
          )
        end

        let(:environment) { 'review/name' }

        subject { project.deployment_platform(environment: environment) }

        context 'when environment scope is exactly matched' do
          before do
            cluster.update!(environment_scope: 'review/name')
          end

          it_behaves_like 'matching environment scope'
        end

        context 'when environment scope is matched by wildcard' do
          before do
            cluster.update!(environment_scope: 'review/*')
          end

          it_behaves_like 'matching environment scope'
        end

        context 'when environment scope does not match' do
          before do
            cluster.update!(environment_scope: 'review/*/special')
          end

          it_behaves_like 'not matching environment scope'
        end

        context 'when environment scope has _' do
          it 'does not treat it as wildcard' do
            cluster.update!(environment_scope: 'foo_bar/*')

            is_expected.to eq(default_cluster.platform_kubernetes)
          end

          context 'when environment name contains an underscore' do
            let(:environment) { 'foo_bar/test' }

            it 'matches literally for _' do
              cluster.update!(environment_scope: 'foo_bar/*')

              is_expected.to eq(cluster.platform_kubernetes)
            end
          end
        end

        # The environment name and scope cannot have % at the moment,
        # but we're considering relaxing it and we should also make sure
        # it doesn't break in case some data sneaked in somehow as we're
        # not checking this integrity in database level.
        context 'when environment scope has %' do
          it 'does not treat it as wildcard' do
            cluster.update_attribute(:environment_scope, '*%*')

            is_expected.to eq(default_cluster.platform_kubernetes)
          end

          context 'when environment name contains a percent char' do
            let(:environment) { 'foo%bar/test' }

            it 'matches literally for %' do
              cluster.update_attribute(:environment_scope, 'foo%bar/*')

              is_expected.to eq(cluster.platform_kubernetes)
            end
          end
        end

        context 'when perfectly matched cluster exists' do
          let!(:perfectly_matched_cluster) { create(:cluster, :provided_by_user, projects: [project], environment_scope: 'review/name') }

          it 'returns perfectly matched cluster as highest precedence' do
            is_expected.to eq(perfectly_matched_cluster.platform_kubernetes)
          end
        end
      end

      context 'with multiple clusters and multiple environments' do
        let!(:cluster_1) { create(:cluster, :provided_by_user, projects: [project], environment_scope: 'staging/*') }
        let!(:cluster_2) { create(:cluster, :provided_by_user, projects: [project], environment_scope: 'test/*') }

        let(:environment_1) { 'staging/name' }
        let(:environment_2) { 'test/name' }

        it 'returns the appropriate cluster' do
          expect(project.deployment_platform(environment: environment_1)).to eq(cluster_1.platform_kubernetes)
          expect(project.deployment_platform(environment: environment_2)).to eq(cluster_2.platform_kubernetes)
        end
      end
    end

    context 'with no Kubernetes configuration on CI/CD, no Kubernetes Service' do
      it { is_expected.to be_nil }
    end

    context 'when project is the cluster\'s management project ' do
      let(:another_project) { create(:project, namespace: project.namespace) }

      let!(:cluster_with_management_project) do
        create(:cluster, :provided_by_user, projects: [another_project], management_project: project)
      end

      it 'returns the cluster with management project' do
        is_expected.to eq(cluster_with_management_project.platform_kubernetes)
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
        let(:another_project) { create(:project, namespace: project.namespace) }

        let!(:cluster_with_management_project) do
          create(:cluster, :provided_by_user, projects: [another_project], management_project: project)
        end

        it 'returns the cluster with management project' do
          is_expected.to eq(cluster_with_management_project.platform_kubernetes)
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

    context 'when instance has configured kubernetes cluster' do
      let!(:instance_cluster) { create(:cluster, :provided_by_user, :instance) }

      it 'returns the Kubernetes platform' do
        is_expected.to eq(instance_cluster.platform_kubernetes)
      end
    end
  end
end

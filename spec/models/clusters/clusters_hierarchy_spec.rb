# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::ClustersHierarchy do
  describe '#base_and_ancestors' do
    def base_and_ancestors(clusterable)
      described_class.new(clusterable).base_and_ancestors
    end

    context 'project in nested group with clusters at every level' do
      let!(:cluster) { create(:cluster, :project, projects: [project]) }
      let!(:child) { create(:cluster, :group, groups: [child_group]) }
      let!(:parent) { create(:cluster, :group, groups: [parent_group]) }
      let!(:ancestor) { create(:cluster, :group, groups: [ancestor_group]) }

      let(:ancestor_group) { create(:group) }
      let(:parent_group) { create(:group, parent: ancestor_group) }
      let(:child_group) { create(:group, parent: parent_group) }
      let(:project) { create(:project, group: child_group) }

      it 'returns clusters for project' do
        expect(base_and_ancestors(project)).to eq([cluster, child, parent, ancestor])
      end

      it 'returns clusters for child_group' do
        expect(base_and_ancestors(child_group)).to eq([child, parent, ancestor])
      end

      it 'returns clusters for parent_group' do
        expect(base_and_ancestors(parent_group)).to eq([parent, ancestor])
      end

      it 'returns clusters for ancestor_group' do
        expect(base_and_ancestors(ancestor_group)).to eq([ancestor])
      end
    end

    context 'project in a namespace' do
      let!(:cluster) { create(:cluster, :project) }

      it 'returns clusters for project' do
        expect(base_and_ancestors(cluster.project)).to eq([cluster])
      end

      context 'cluster has management project' do
        let(:management_project) { create(:project, namespace: cluster.first_project.namespace) }

        before do
          cluster.update!(management_project: management_project)
        end

        context 'management_project is in same namespace as cluster' do
          it 'returns cluster for management_project' do
            expect(base_and_ancestors(management_project)).to eq([cluster])
          end
        end

        context 'management_project is in a different namespace from cluster' do
          let(:management_project) { create(:project) }

          it 'returns nothing' do
            expect(base_and_ancestors(management_project)).to be_empty
          end
        end
      end
    end

    context 'cluster has management project' do
      let!(:project_cluster) { create(:cluster, :project, projects: [project]) }
      let!(:group_cluster) { create(:cluster, :group, groups: [group], management_project: management_project) }

      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }
      let(:management_project) { create(:project, group: group) }

      it 'returns clusters for management_project' do
        expect(base_and_ancestors(management_project)).to eq([group_cluster])
      end

      it 'returns clusters for project' do
        expect(base_and_ancestors(project)).to eq([project_cluster, group_cluster])
      end

      it 'returns clusters for group' do
        expect(base_and_ancestors(group)).to eq([group_cluster])
      end
    end

    context 'project in nested group with clusters at some levels' do
      let!(:child) { create(:cluster, :group, groups: [child_group]) }
      let!(:ancestor) { create(:cluster, :group, groups: [ancestor_group], management_project: management_project) }

      let(:ancestor_group) { create(:group) }
      let(:parent_group) { create(:group, parent: ancestor_group) }
      let(:child_group) { create(:group, parent: parent_group) }
      let(:project) { create(:project, group: child_group) }
      let(:management_project) { create(:project, group: child_group) }

      it 'returns clusters for management_project' do
        expect(base_and_ancestors(management_project)).to eq([ancestor, child])
      end

      it 'returns clusters for project' do
        expect(base_and_ancestors(project)).to eq([child, ancestor])
      end

      it 'returns clusters for child_group' do
        expect(base_and_ancestors(child_group)).to eq([child, ancestor])
      end

      it 'returns clusters for parent_group' do
        expect(base_and_ancestors(parent_group)).to eq([ancestor])
      end

      it 'returns clusters for ancestor_group' do
        expect(base_and_ancestors(ancestor_group)).to eq([ancestor])
      end
    end
  end
end

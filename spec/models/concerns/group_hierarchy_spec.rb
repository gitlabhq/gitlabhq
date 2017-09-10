require 'spec_helper'

describe GroupHierarchy, :nested_groups do
  let(:parent) { create(:group) }
  let(:subgroup) { create(:group, parent: parent) }
  let(:subsub_group) { create(:group, parent: subgroup) }

  context 'for a group' do
    describe '#hierarchy' do
      it 'builds a hierarchy for a group' do
        expected_hierarchy = { parent => { subgroup => subsub_group } }

        expect(subsub_group.hierarchy).to eq(expected_hierarchy)
      end

      it 'builds a hierarchy upto a specified parent' do
        expected_hierarchy = { subgroup => subsub_group }

        expect(subsub_group.hierarchy(parent)).to eq(expected_hierarchy)
      end

      it 'raises an error if specifying a base that is not part of the tree' do
        expect { subsub_group.hierarchy(double) }.to raise_error('specified base is not part of the tree')
      end
    end

    describe '#parent' do
      it 'returns the correct parent' do
        expect(subsub_group.parent).to eq(subgroup)
      end
    end

    describe '#merge_hierarchy' do
      it 'combines hierarchies' do
        other_subgroup = create(:group, parent: parent)

        expected_hierarchy = { parent => [{ subgroup => subsub_group }, other_subgroup] }

        expect(subsub_group.merge_hierarchy(other_subgroup)).to eq(expected_hierarchy)
      end
    end

    describe '.merge_hierarchies' do
      it 'combines hierarchies until the top' do
        other_subgroup = create(:group, parent: parent)
        other_subsub_group = create(:group, parent: subgroup)

        groups = [other_subgroup, subsub_group, other_subsub_group]

        expected_hierarchy = { parent => [other_subgroup, { subgroup => [subsub_group, other_subsub_group] }] }

        expect(described_class.merge_hierarchies(groups)).to eq(expected_hierarchy)
      end

      it 'combines upto a given parent' do
        other_subgroup = create(:group, parent: parent)
        other_subsub_group = create(:group, parent: subgroup)

        groups = [other_subgroup, subsub_group, other_subsub_group]

        expected_hierarchy = [other_subgroup, { subgroup => [subsub_group, other_subsub_group] }]

        expect(described_class.merge_hierarchies(groups, parent)).to eq(expected_hierarchy)
      end
    end
  end

  context 'for a project' do
    let(:project) { create(:project, namespace: subsub_group) }

    describe '#hierarchy' do
      it 'builds a hierarchy for a group' do
        expected_hierarchy = { parent => { subgroup => { subsub_group => project } } }

        expect(project.hierarchy).to eq(expected_hierarchy)
      end

      it 'builds a hierarchy upto a specified parent' do
        expected_hierarchy = { subsub_group => project }

        expect(project.hierarchy(subgroup)).to eq(expected_hierarchy)
      end

      it 'raises an error if specifying a base that is not part of the tree' do
        expect { project.hierarchy(double) }.to raise_error('specified base is not part of the tree')
      end
    end

    describe '#parent' do
      it 'returns the correct parent' do
        expect(project.parent).to eq(subsub_group)
      end
    end

    describe '#merge_hierarchy' do
      it 'combines hierarchies' do
        project = create(:project, namespace: parent)

        expected_hierarchy = { parent => [{ subgroup => subsub_group }, project] }

        expect(subsub_group.merge_hierarchy(project)).to eq(expected_hierarchy)
      end
    end

    describe '.merge_hierarchies' do
      it 'combines hierarchies until the top' do
        other_project = create(:project, namespace: parent)
        other_subgroup_project = create(:project, namespace: subgroup)

        elements = [other_project, subsub_group, other_subgroup_project]

        expected_hierarchy = { parent => [other_project, { subgroup => [subsub_group, other_subgroup_project] }] }

        expect(described_class.merge_hierarchies(elements)).to eq(expected_hierarchy)
      end

      it 'combines upto a given parent' do
        other_project = create(:project, namespace: parent)
        other_subgroup_project = create(:project, namespace: subgroup)

        elements = [other_project, subsub_group, other_subgroup_project]

        expected_hierarchy = [other_project, { subgroup => [subsub_group, other_subgroup_project] }]

        expect(described_class.merge_hierarchies(elements, parent)).to eq(expected_hierarchy)
      end

      it 'merges to elements in the same hierarchy' do
        expected_hierarchy = { parent => subgroup }

        expect(described_class.merge_hierarchies([parent, subgroup])).to eq(expected_hierarchy)
      end
    end
  end
end

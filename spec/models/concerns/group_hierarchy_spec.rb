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
  end
end

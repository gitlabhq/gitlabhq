require 'spec_helper'

describe GroupDescendant, :nested_groups do
  let(:parent) { create(:group) }
  let(:subgroup) { create(:group, parent: parent) }
  let(:subsub_group) { create(:group, parent: subgroup) }

  def all_preloaded_groups(*groups)
    groups + [parent, subgroup, subsub_group]
  end

  context 'for a group' do
    describe '#hierarchy' do
      it 'only queries once for the ancestors' do
        # make sure the subsub_group does not have anything cached
        test_group = create(:group, parent: subsub_group).reload

        query_count = ActiveRecord::QueryRecorder.new { test_group.hierarchy }.count

        expect(query_count).to eq(1)
      end

      it 'only queries once for the ancestors when a top is given' do
        test_group = create(:group, parent: subsub_group).reload

        recorder = ActiveRecord::QueryRecorder.new { test_group.hierarchy(subgroup) }
        expect(recorder.count).to eq(1)
      end

      it 'builds a hierarchy for a group' do
        expected_hierarchy = { parent => { subgroup => subsub_group } }

        expect(subsub_group.hierarchy).to eq(expected_hierarchy)
      end

      it 'builds a hierarchy upto a specified parent' do
        expected_hierarchy = { subgroup => subsub_group }

        expect(subsub_group.hierarchy(parent)).to eq(expected_hierarchy)
      end

      it 'raises an error if specifying a base that is not part of the tree' do
        expect { subsub_group.hierarchy(build_stubbed(:group)) }
          .to raise_error('specified top is not part of the tree')
      end
    end

    describe '.build_hierarchy' do
      it 'combines hierarchies until the top' do
        other_subgroup = create(:group, parent: parent)
        other_subsub_group = create(:group, parent: subgroup)

        groups = all_preloaded_groups(other_subgroup, subsub_group, other_subsub_group)

        expected_hierarchy = { parent => [other_subgroup, { subgroup => [subsub_group, other_subsub_group] }] }

        expect(described_class.build_hierarchy(groups)).to eq(expected_hierarchy)
      end

      it 'combines upto a given parent' do
        other_subgroup = create(:group, parent: parent)
        other_subsub_group = create(:group, parent: subgroup)

        groups = [other_subgroup, subsub_group, other_subsub_group]
        groups << subgroup # Add the parent as if it was preloaded

        expected_hierarchy = [other_subgroup, { subgroup => [subsub_group, other_subsub_group] }]
        expect(described_class.build_hierarchy(groups, parent)).to eq(expected_hierarchy)
      end

      it 'handles building a tree out of order' do
        other_subgroup = create(:group, parent: parent)
        other_subgroup2 = create(:group, parent: parent)
        other_subsub_group = create(:group, parent: other_subgroup)

        groups = all_preloaded_groups(subsub_group, other_subgroup2, other_subsub_group, other_subgroup)
        expected_hierarchy = { parent => [{ subgroup => subsub_group }, other_subgroup2, { other_subgroup => other_subsub_group }] }

        expect(described_class.build_hierarchy(groups)).to eq(expected_hierarchy)
      end

      it 'tracks the exception when a parent was not preloaded' do
        expect(Gitlab::Sentry).to receive(:track_exception).and_call_original

        expect { GroupDescendant.build_hierarchy([subsub_group]) }.to raise_error(ArgumentError)
      end

      it 'recovers if a parent was not reloaded by querying for the parent' do
        expected_hierarchy = { parent => { subgroup => subsub_group } }

        # this does not raise in production, so stubbing it here.
        allow(Gitlab::Sentry).to receive(:track_exception)

        expect(GroupDescendant.build_hierarchy([subsub_group])).to eq(expected_hierarchy)
      end

      it 'raises an error if not all elements were preloaded' do
        expect { described_class.build_hierarchy([subsub_group]) }
          .to raise_error(/was not preloaded/)
      end
    end
  end

  context 'for a project' do
    let(:project) { create(:project, namespace: subsub_group) }

    describe '#hierarchy' do
      it 'builds a hierarchy for a project' do
        expected_hierarchy = { parent => { subgroup => { subsub_group => project } } }

        expect(project.hierarchy).to eq(expected_hierarchy)
      end

      it 'builds a hierarchy upto a specified parent' do
        expected_hierarchy = { subsub_group => project }

        expect(project.hierarchy(subgroup)).to eq(expected_hierarchy)
      end
    end

    describe '.build_hierarchy' do
      it 'combines hierarchies until the top' do
        other_project = create(:project, namespace: parent)
        other_subgroup_project = create(:project, namespace: subgroup)

        elements = all_preloaded_groups(other_project, subsub_group, other_subgroup_project)

        expected_hierarchy = { parent => [other_project, { subgroup => [subsub_group, other_subgroup_project] }] }

        expect(described_class.build_hierarchy(elements)).to eq(expected_hierarchy)
      end

      it 'combines upto a given parent' do
        other_project = create(:project, namespace: parent)
        other_subgroup_project = create(:project, namespace: subgroup)

        elements = [other_project, subsub_group, other_subgroup_project]
        elements << subgroup # Added as if it was preloaded

        expected_hierarchy = [other_project, { subgroup => [subsub_group, other_subgroup_project] }]

        expect(described_class.build_hierarchy(elements, parent)).to eq(expected_hierarchy)
      end

      it 'merges to elements in the same hierarchy' do
        expected_hierarchy = { parent => subgroup }

        expect(described_class.build_hierarchy([parent, subgroup])).to eq(expected_hierarchy)
      end

      it 'merges complex hierarchies' do
        project = create(:project, namespace: parent)
        sub_project = create(:project, namespace: subgroup)
        subsubsub_group = create(:group, parent: subsub_group)
        subsub_project = create(:project, namespace: subsub_group)
        subsubsub_project = create(:project, namespace: subsubsub_group)
        other_subgroup = create(:group, parent: parent)
        other_subproject = create(:project, namespace: other_subgroup)

        elements = [project, subsubsub_project, sub_project, other_subproject, subsub_project]
        # Add parent groups as if they were preloaded
        elements += [other_subgroup, subsubsub_group, subsub_group, subgroup]

        expected_hierarchy = [
          project,
          {
            subgroup => [
              { subsub_group => [{ subsubsub_group => subsubsub_project }, subsub_project] },
              sub_project
            ]
          },
          { other_subgroup => other_subproject }
        ]

        actual_hierarchy = described_class.build_hierarchy(elements, parent)

        expect(actual_hierarchy).to eq(expected_hierarchy)
      end
    end
  end
end

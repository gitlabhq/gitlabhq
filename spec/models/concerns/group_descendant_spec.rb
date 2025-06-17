# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDescendant do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:parent) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: parent) }
  let_it_be(:subsub_group) { create(:group, parent: subgroup) }

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

      context 'with upto_preloaded_ancestors_only option' do
        where :top, :preloaded, :expected_hierarchy do
          nil          | []                             | ref(:subsub_group)
          nil          | [ref(:parent)]                 | ref(:subsub_group)
          nil          | [ref(:subgroup)]               | { ref(:subgroup) => ref(:subsub_group) }
          nil          | [ref(:parent), ref(:subgroup)] | { ref(:parent) => { ref(:subgroup) => ref(:subsub_group) } }
          ref(:parent) | []                             | ref(:subsub_group)
          ref(:parent) | [ref(:parent)]                 | ref(:subsub_group)
          ref(:parent) | [ref(:subgroup)]               | { ref(:subgroup) => ref(:subsub_group) }
          ref(:parent) | [ref(:parent), ref(:subgroup)] | { ref(:subgroup) => ref(:subsub_group) }
        end

        with_them do
          subject { subsub_group.hierarchy(top, preloaded, { upto_preloaded_ancestors_only: true }) }

          it 'builds hierarchy upto preloaded ancestors only' do
            is_expected.to eq(expected_hierarchy)
          end
        end
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

      context 'when parent is not preloaded' do
        it 'tracks the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

          expect { described_class.build_hierarchy([subsub_group]) }.to raise_error(ArgumentError)
        end

        it 'includes the backtrace' do
          allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          described_class.build_hierarchy([subsub_group])

          expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
            .at_least(:once) do |exception, _|
            expect(exception.backtrace).to be_present
          end
        end
      end

      it 'recovers if a parent was not reloaded by querying for the parent' do
        expected_hierarchy = { parent => { subgroup => subsub_group } }

        # this does not raise in production, so stubbing it here.
        allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

        expect(described_class.build_hierarchy([subsub_group])).to eq(expected_hierarchy)
      end

      it 'raises an error if not all elements were preloaded' do
        expect { described_class.build_hierarchy([subsub_group]) }
          .to raise_error(/was not preloaded/)
      end

      context 'with upto_preloaded_ancestors_only option' do
        let_it_be(:other_subgroup) { create(:group, parent: parent) }
        let_it_be(:descendants) { [subgroup, other_subgroup, subsub_group] }

        subject do
          described_class.build_hierarchy(descendants, nil, { upto_preloaded_ancestors_only: true })
        end

        it "builds descendant's hierarchies with the preloaded ancestors only" do
          is_expected.to match_array([{ subgroup => subsub_group }, other_subgroup])
        end
      end
    end
  end

  context 'for a project' do
    let_it_be(:project) { create(:project, namespace: subsub_group) }

    describe '#hierarchy' do
      it 'builds a hierarchy for a project' do
        expected_hierarchy = { parent => { subgroup => { subsub_group => project } } }

        expect(project.hierarchy).to eq(expected_hierarchy)
      end

      it 'builds a hierarchy upto a specified parent' do
        expected_hierarchy = { subsub_group => project }

        expect(project.hierarchy(subgroup)).to eq(expected_hierarchy)
      end

      context 'with upto_preloaded_ancestors_only option' do
        where :top, :preloaded, :expected_hierarchy do
          nil            | []                                   | ref(:project)
          nil            | [ref(:subgroup)]                     | ref(:project)
          nil            | [ref(:subsub_group)]                 | { ref(:subsub_group) => ref(:project) }
          nil            | [ref(:subgroup), ref(:subsub_group)] | { ref(:subgroup) => { ref(:subsub_group) => ref(:project) } }
          ref(:subgroup) | []                                   | ref(:project)
          ref(:subgroup) | [ref(:subgroup)]                     | ref(:project)
          ref(:subgroup) | [ref(:subsub_group)]                 | { ref(:subsub_group) => ref(:project) }
          ref(:subgroup) | [ref(:subgroup), ref(:subsub_group)] | { ref(:subsub_group) => ref(:project) }
        end

        with_them do
          subject { project.hierarchy(top, preloaded, { upto_preloaded_ancestors_only: true }) }

          it 'builds hierarchy upto preloaded ancestors only' do
            is_expected.to eq(expected_hierarchy)
          end
        end
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

      context 'with upto_preloaded_ancestors_only option' do
        let_it_be(:other_subgroup) { create(:group, parent: parent) }
        let_it_be(:descendants) { [subgroup, other_subgroup, subsub_group, project] }

        subject do
          described_class.build_hierarchy(descendants, nil, { upto_preloaded_ancestors_only: true })
        end

        it "builds descendant's hierarchies with the preloaded ancestors only" do
          is_expected.to match_array([{ subgroup => { subsub_group => project } }, other_subgroup])
        end
      end
    end
  end
end

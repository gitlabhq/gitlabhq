# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::StateQuerying, feature_category: :groups_and_projects do
  include Namespaces::StatefulHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) { create(:namespace) }

  describe '#effective_state' do
    context 'with explicit state' do
      where(:state_key) do
        %i[
          archived
          transfer_in_progress
          maintenance
          deletion_scheduled
          creation_in_progress
          deletion_in_progress
        ]
      end

      with_them do
        it 'returns the namespace own state' do
          namespace.state = Namespaces::Stateful::STATES[state_key]
          expect(namespace.effective_state).to eq(state_key)
        end
      end
    end

    context 'with ancestor_inherited state' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:parent_group) { create(:group, parent: root_group) }
      let_it_be(:child_group) { create(:group, parent: parent_group) }

      before do
        set_state(child_group, :ancestor_inherited)
      end

      describe 'hierarchy resolution' do
        where(:root_state, :parent_state, :expected_state) do
          :ancestor_inherited | :ancestor_inherited | :ancestor_inherited
          :ancestor_inherited | :archived           | :archived
          :maintenance        | :ancestor_inherited | :maintenance
          :maintenance        | :archived           | :archived
        end

        with_them do
          it 'resolves to expected state based on ancestor hierarchy' do
            set_state(root_group, root_state)
            set_state(parent_group, parent_state)

            expect(child_group.effective_state).to eq(expected_state)
          end
        end
      end

      it 'returns ancestor_inherited for top-level namespace with ancestor_inherited state' do
        set_state(root_group, :ancestor_inherited)
        expect(root_group.effective_state).to eq(:ancestor_inherited)
      end

      it 'resolves deeply nested hierarchies correctly' do
        grandchild_group = create(:group, parent: child_group)
        set_state(grandchild_group, :ancestor_inherited)
        set_state(root_group, :transfer_in_progress)
        set_state(parent_group, :ancestor_inherited)
        set_state(child_group, :ancestor_inherited)

        expect(grandchild_group.effective_state).to eq(:transfer_in_progress)
      end

      it 'returns closest ancestor state, not based on ID ordering' do
        # The group hierarchy is such that: root.id > parent.id > child.id
        child = create(:group, state: Namespaces::Stateful::STATES[:ancestor_inherited])
        parent = create(:group, state: Namespaces::Stateful::STATES[:archived])
        root = create(:group, state: Namespaces::Stateful::STATES[:maintenance])

        # Set the ancestry such that: child.traversal_ids: [root.id, parent.id, child.id]
        child.parent = parent
        parent.parent = root
        child.save!
        parent.save!
        root.reload

        # Should return parent's state (:archived), not root's state (:maintenance)
        expect(child.effective_state).to eq(:archived)
      end
    end

    context 'for N+1 query prevention' do
      let_it_be(:root_group) { create(:group, state: Namespaces::Stateful::STATES[:archived]) }

      it 'executes one query per namespace without N+1 queries' do
        child_groups = create_list(:group, 3,
          state: Namespaces::Stateful::STATES[:ancestor_inherited],
          parent: root_group
        )

        queries = ActiveRecord::QueryRecorder.new { child_groups.each(&:effective_state) }

        # Should execute exactly 3 queries (one per child), not N (where N is ancestor count)
        expect(queries.count).to eq(3)
      end
    end
  end

  describe 'scopes' do
    let_it_be(:namespace1) { create(:group) }

    describe '.not_deletion_in_progress' do
      before do
        set_state(namespace1, :deletion_in_progress)
      end

      it 'does not include namespace marked as deleted' do
        expect(Namespace.not_deletion_in_progress).to contain_exactly(namespace)
      end
    end
  end
end

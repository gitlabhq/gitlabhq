# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::StateQuerying, feature_category: :groups_and_projects do
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
          namespace.state = state_key
          expect(namespace.effective_state).to eq(state_key)
        end
      end
    end

    context 'with ancestor_inherited state' do
      let_it_be_with_reload(:root_group) { create(:group) }
      let_it_be_with_reload(:parent_group) { create(:group, parent: root_group) }
      let_it_be_with_reload(:child_group) { create(:group, parent: parent_group) }

      before do
        child_group.update!(state: :ancestor_inherited)
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
            root_group.update!(state: root_state)
            parent_group.update!(state: parent_state)

            expect(child_group.effective_state).to eq(expected_state)
          end
        end
      end

      it 'returns ancestor_inherited for top-level namespace with ancestor_inherited state' do
        root_group.update!(state: :ancestor_inherited)
        expect(root_group.effective_state).to eq(:ancestor_inherited)
      end

      it 'resolves deeply nested hierarchies correctly' do
        grandchild_group = create(:group, parent: child_group)
        grandchild_group.update!(state: :ancestor_inherited)
        root_group.update!(state: :transfer_in_progress)
        parent_group.update!(state: :ancestor_inherited)
        child_group.update!(state: :ancestor_inherited)

        expect(grandchild_group.effective_state).to eq(:transfer_in_progress)
      end

      it 'returns closest ancestor state, not based on ID ordering' do
        # The group hierarchy is such that: root.id > parent.id > child.id
        child = create(:group, state: :ancestor_inherited)
        parent = create(:group, state: :archived)
        root = create(:group, state: :maintenance)

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

    context 'with NULL state during migration' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:child_group) { create(:group, parent: root_group) }

      it 'treats NULL state as ancestor_inherited and resolves to ancestor state' do
        root_group.update!(state: :archived)
        child_group.update_column(:state, nil)
        child_group.reload

        expect(child_group.effective_state).to eq(:archived)
      end

      it 'returns ancestor_inherited when all ancestors also have NULL state' do
        root_group.update_column(:state, nil)
        child_group.update_column(:state, nil)
        root_group.reload
        child_group.reload

        expect(child_group.effective_state).to eq(:ancestor_inherited)
      end
    end

    context 'for N+1 query prevention' do
      let_it_be(:root_group) { create(:group, state: :archived) }

      it 'executes one query per namespace without N+1 queries' do
        child_groups = create_list(:group, 3,
          state: :ancestor_inherited,
          parent: root_group
        )

        queries = ActiveRecord::QueryRecorder.new { child_groups.each(&:effective_state) }

        # Should execute exactly 3 queries (one per child), not N (where N is ancestor count)
        expect(queries.count).to eq(3)
      end
    end
  end

  describe 'scopes' do
    let_it_be_with_reload(:namespace1) { create(:group) }

    describe '.not_deletion_in_progress' do
      before do
        namespace1.update!(state: :deletion_in_progress)
      end

      it 'does not include namespace marked as deleted' do
        expect(Namespace.not_deletion_in_progress).to contain_exactly(namespace)
      end

      it 'includes namespaces with NULL state during migration' do
        namespace.update_column(:state, nil)

        expect(Namespace.not_deletion_in_progress).to contain_exactly(namespace)
      end

      it 'includes namespaces with ancestor_inherited state' do
        namespace.update!(state: :ancestor_inherited)

        expect(Namespace.not_deletion_in_progress).to contain_exactly(namespace)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::StateQuerying, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) { create(:namespace) }

  describe 'delegations' do
    subject { namespace }

    it { is_expected.to delegate_method(:deletion_scheduled_by_user).to(:namespace_details) }
  end

  describe '.deletion_scheduled_before' do
    let_it_be(:cutoff_time) { 10.days.ago }
    let_it_be(:group_not_scheduled) { create(:group) }
    let_it_be(:group_scheduled_after) do
      create(:group, state: :deletion_scheduled, deletion_scheduled_at: cutoff_time + 2.days)
    end

    let_it_be(:group_scheduled_before) do
      create(:group, state: :deletion_scheduled, deletion_scheduled_at: cutoff_time - 2.days)
    end

    let_it_be(:group_scheduled_on_cutoff) do
      create(:group, state: :deletion_scheduled, deletion_scheduled_at: cutoff_time)
    end

    subject(:relation) { Group.deletion_scheduled_before(cutoff_time) }

    it 'includes namespaces scheduled for deletion on or before the specified time' do
      expect(relation).to include(group_scheduled_before, group_scheduled_on_cutoff)
    end

    it 'excludes namespaces scheduled after the specified time or not scheduled at all' do
      expect(relation).not_to include(group_scheduled_after, group_not_scheduled)
    end
  end

  describe '.with_deletion_scheduled_by_user' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) do
      create(:group, state: :deletion_scheduled, state_metadata: { deletion_scheduled_by_user_id: user.id })
    end

    it 'eager loads the deletion_scheduled_by_user association through namespace_details' do
      result = Group.where(id: group.id).with_deletion_scheduled_by_user.first

      expect(result.namespace_details.association(:deletion_scheduled_by_user)).to be_loaded
    end
  end

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
end

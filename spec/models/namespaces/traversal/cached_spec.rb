# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Traversal::Cached, feature_category: :database do
  describe 'callbacks' do
    let_it_be_with_refind(:old_parent) { create(:group) }
    let_it_be_with_refind(:new_parent) { create(:group) }
    let_it_be_with_refind(:group) { create(:group, parent: old_parent) }
    let_it_be_with_refind(:subgroup) { create(:group, parent: group) }

    context 'when no cached records are present' do
      it 'does nothing' do
        group.parent = new_parent

        expect { group.save! }.not_to change { Namespaces::Descendants.all.to_a }
      end
    end

    context 'when the namespace record is UserNamespace' do
      it 'does nothing' do
        # we won't use the optimization for UserNamespace
        namespace = create(:user_namespace)
        cache = create(:namespace_descendants, namespace: namespace)

        expect { namespace.destroy! }.not_to change { cache.reload.outdated_at }
      end
    end

    context 'when cached record is present' do
      let!(:cache) { create(:namespace_descendants, namespace: group) }

      it 'invalidates the cache' do
        expect { group.update!(parent: new_parent) }.to change { cache.reload.outdated_at }.from(nil)
      end

      it 'does not invalidate the cache of subgroups' do
        subgroup_cache = create(:namespace_descendants, namespace: subgroup)

        expect { group.update!(parent: new_parent) }.not_to change { subgroup_cache.reload.outdated_at }
      end

      context 'when a new subgroup is added' do
        it 'invalidates the cache' do
          expect { create(:group, parent: group) }.to change { cache.reload.outdated_at }
        end

        context 'when shared_namespace_locks feature flag is disabled' do
          before do
            stub_feature_flags(shared_namespace_locks: false)
          end

          it 'invalidates the cache' do
            expect { create(:group, parent: group) }.to change { cache.reload.outdated_at }
          end
        end
      end

      context 'when a new project is added' do
        it 'invalidates the cache' do
          expect { create(:project, group: group) }.to change { cache.reload.outdated_at }
        end

        context 'when shared_namespace_locks feature flag is disabled' do
          before do
            stub_feature_flags(shared_namespace_locks: false)
          end

          it 'invalidates the cache' do
            expect { create(:project, group: group) }.to change { cache.reload.outdated_at }
          end
        end
      end
    end

    context 'when parent group has cached record' do
      it 'invalidates the parent cache' do
        old_parent_cache = create(:namespace_descendants, namespace: old_parent)
        new_parent_cache = create(:namespace_descendants, namespace: new_parent)

        group.update!(parent: new_parent)

        expect(old_parent_cache.reload.outdated_at).not_to be_nil
        expect(new_parent_cache.reload.outdated_at).not_to be_nil
      end
    end

    context 'when group is destroyed' do
      it 'invalidates the cache' do
        subgroup.destroy!
        cache = create(:namespace_descendants, namespace: group)

        expect { group.destroy! }.to change { cache.reload.outdated_at }.from(nil)
      end

      context 'when parent group has cached record' do
        it 'invalidates the parent cache' do
          old_parent_cache = create(:namespace_descendants, namespace: old_parent)
          new_parent_cache = create(:namespace_descendants, namespace: new_parent)

          subgroup.destroy!
          group.destroy!

          expect(old_parent_cache.reload.outdated_at).not_to be_nil
          expect(new_parent_cache.reload.outdated_at).to be_nil # no change
        end
      end
    end
  end

  describe 'query methods' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:subsubgroup) { create(:group, parent: subgroup) }

    let_it_be(:project1) { create(:project, group: group) }
    let_it_be(:project2) { create(:project, group: subsubgroup) }

    # deliberately making self_and_descendant_group_ids different from  the actual
    # self_and_descendant_ids so we can verify that the cached query is running.
    let_it_be_with_refind(:namespace_descendants) do
      create(:namespace_descendants,
        :up_to_date,
        namespace: group,
        self_and_descendant_group_ids: [group.id, subgroup.id],
        all_project_ids: [project1.id]
      )
    end

    describe '#self_and_descendant_ids' do
      subject(:ids) { group.self_and_descendant_ids.pluck(:id) }

      it 'returns the cached values' do
        expect(ids).to eq(namespace_descendants.self_and_descendant_group_ids)
      end

      context 'when the cache is outdated' do
        it 'returns the values from the uncached self_and_descendant_ids query' do
          namespace_descendants.update!(outdated_at: Time.current)

          expect(ids.sort).to eq([group.id, subgroup.id, subsubgroup.id])
        end
      end

      context 'when the group_hierarchy_optimization feature flag is disabled' do
        before do
          stub_feature_flags(group_hierarchy_optimization: false)
        end

        it 'returns the values from the uncached self_and_descendant_ids query' do
          expect(ids.sort).to eq([group.id, subgroup.id, subsubgroup.id])
        end
      end

      context 'when the scope is specified' do
        it 'returns uncached values that match the scope' do
          ids = group.self_and_descendant_ids(skope: Namespace).pluck(:id)

          expect(ids).to contain_exactly(
            group.id, subgroup.id, subsubgroup.id, project1.project_namespace.id, project2.project_namespace.id
          )
        end
      end
    end

    describe '#all_project_ids' do
      subject(:ids) { group.all_project_ids.pluck(:id) }

      it 'returns the cached values' do
        expect(ids).to eq(namespace_descendants.all_project_ids)
      end

      context 'when the cache is outdated' do
        it 'returns the values from the uncached all_project_ids query' do
          namespace_descendants.update!(outdated_at: Time.current)

          expect(ids.sort).to eq([project1.id, project2.id])
        end
      end

      context 'when the group_hierarchy_optimization feature flag is disabled' do
        before do
          stub_feature_flags(group_hierarchy_optimization: false)
        end

        it 'returns the values from the uncached all_project_ids query' do
          expect(ids.sort).to eq([project1.id, project2.id])
        end
      end
    end
  end
end

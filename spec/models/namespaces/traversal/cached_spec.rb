# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Traversal::Cached, feature_category: :database do
  let_it_be_with_refind(:old_parent) { create(:group) }
  let_it_be_with_refind(:new_parent) { create(:group) }
  let_it_be_with_refind(:group) { create(:group, parent: old_parent) }
  let_it_be_with_refind(:subgroup) { create(:group, parent: group) }

  context 'when the namespace_descendants_cache_expiration feature flag is off' do
    let!(:cache) { create(:namespace_descendants, namespace: group) }

    before do
      stub_feature_flags(namespace_descendants_cache_expiration: false)
    end

    it 'does not invalidate the cache' do
      expect { group.update!(parent: new_parent) }.not_to change { cache.reload.outdated_at }
    end

    context 'when the group is deleted' do
      it 'invalidates the cache' do
        expect { group.destroy! }.not_to change { cache.reload.outdated_at }
      end
    end
  end

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
    end

    context 'when a new project is added' do
      it 'invalidates the cache' do
        expect { create(:project, group: group) }.to change { cache.reload.outdated_at }
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
      cache = create(:namespace_descendants, namespace: group)

      expect { group.destroy! }.to change { cache.reload.outdated_at }.from(nil)
    end

    context 'when parent group has cached record' do
      it 'invalidates the parent cache' do
        old_parent_cache = create(:namespace_descendants, namespace: old_parent)
        new_parent_cache = create(:namespace_descendants, namespace: new_parent)

        group.destroy!

        expect(old_parent_cache.reload.outdated_at).not_to be_nil
        expect(new_parent_cache.reload.outdated_at).to be_nil # no change
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::UpdateDenormalizedDescendantsService, feature_category: :database do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:subsub_group) { create(:group, parent: subgroup) }

  let_it_be(:project1) { create(:project, group: subgroup) }
  let_it_be(:project2) { create(:project, group: subsub_group, archived: true) }

  let_it_be_with_reload(:cache) do
    create(:namespace_descendants,
      :outdated,
      calculated_at: nil,
      namespace: subgroup,
      # outdated values:
      traversal_ids: [group.id + 100, subgroup.id],
      self_and_descendant_ids: [],
      self_and_descendant_group_ids: [],
      all_project_ids: [project1.id],
      all_unarchived_project_ids: [project1.id]
    )
  end

  def run_service(id)
    described_class.new(namespace_id: id).execute
  end

  it 'updates an outdated cache' do
    result = run_service(subgroup.id)

    cache.reload

    expect(cache).to have_attributes(
      traversal_ids: [group.id, subgroup.id],
      self_and_descendant_ids: [subgroup.id, subsub_group.id,
        project1.project_namespace_id, project2.project_namespace_id],
      self_and_descendant_group_ids: [subgroup.id, subsub_group.id],
      all_project_ids: [project1.id, project2.id],
      all_unarchived_project_ids: [project1.id],
      outdated_at: nil
    )

    expect(result).to eq(:processed)
  end

  context 'when the outdated namespace is outdated again while the service is running' do
    it 'keeps the record outdated' do
      allow(Namespaces::Descendants).to receive(:upsert_with_consistent_data)
        .and_wrap_original do |original_method, *args, **kwargs|
          cache.update!(outdated_at: 1.hour.from_now)
          original_method.call(*args, **kwargs)
        end

      result = run_service(subgroup.id)

      cache.reload

      expect(cache.outdated_at).not_to be_nil
      expect(result).to eq(:not_updated_due_to_optimistic_lock)
    end
  end

  context 'when lock timeout happens when updating the descendants record' do
    it 'keeps the record outdated' do
      allow(Namespaces::Descendants).to receive(:upsert_with_consistent_data).and_raise(ActiveRecord::LockWaitTimeout)

      result = run_service(subgroup.id)

      cache.reload

      expect(cache.outdated_at).not_to be_nil
      expect(result).to eq(:not_updated_due_to_lock_timeout)
    end
  end

  context 'when the namespace was removed in the meantime' do
    it 'removes the cache record' do
      namespace_id = non_existing_record_id
      create(:namespace_descendants, namespace_id: namespace_id)

      run_service(namespace_id)

      record = Namespaces::Descendants.find_by(namespace_id: namespace_id)
      expect(record).to eq(nil)
    end
  end

  context 'when passing in a non existing namespace' do
    it 'does nothing' do
      expect { run_service(non_existing_record_id) }.not_to change { Namespaces::Descendants.all.sort }
    end
  end

  context 'when passing in a namespace without cache' do
    it 'does nothing' do
      expect { run_service(group) }.not_to change { Namespaces::Descendants.all.sort }
    end
  end
end

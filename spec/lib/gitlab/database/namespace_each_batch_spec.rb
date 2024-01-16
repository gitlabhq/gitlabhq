# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::NamespaceEachBatch, feature_category: :database do
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:user) { create(:user, :admin) }

  let(:namespace_id) { group.id }

  let_it_be(:subgroup1) { create(:group, parent: group) }
  let_it_be(:subgroup2) { create(:group, parent: group) }

  let_it_be(:subsubgroup1) { create(:group, parent: subgroup1) }
  let_it_be(:subsubgroup2) { create(:group, parent: subgroup1) }
  let_it_be(:subsubgroup3) { create(:group, parent: subgroup1) }

  let_it_be(:project1) { create(:project, namespace: group) }
  let_it_be(:project2) { create(:project, namespace: group) }
  let_it_be(:project3) { create(:project, namespace: subsubgroup2) }
  let_it_be(:project4) { create(:project, namespace: subsubgroup3) }
  let_it_be(:project5) { create(:project, namespace: subsubgroup3) }

  let(:namespace_class) { Namespace }
  let(:batch_size) { 3 }

  def collected_ids(cursor = { current_id: namespace_id, depth: [namespace_id] })
    [].tap do |ids|
      described_class.new(namespace_class: namespace_class, cursor: cursor).each_batch(of: batch_size) do |batch_ids|
        ids.concat(batch_ids)
      end
    end
  end

  shared_examples 'iteration over the hierarchy' do
    it 'returns the correct namespace ids' do
      expect(collected_ids).to eq([
        group.id,
        subgroup1.id,
        subsubgroup1.id,
        subsubgroup2.id,
        project3.project_namespace_id,
        subsubgroup3.id,
        project4.project_namespace_id,
        project5.project_namespace_id,
        subgroup2.id,
        project1.project_namespace_id,
        project2.project_namespace_id
      ])
    end
  end

  it_behaves_like 'iteration over the hierarchy'

  context 'when batch size is larger than the hierarchy' do
    let(:batch_size) { 100 }

    it_behaves_like 'iteration over the hierarchy'
  end

  context 'when batch size is 1' do
    let(:batch_size) { 1 }

    it_behaves_like 'iteration over the hierarchy'
  end

  context 'when stopping the iteration in the middle and resuming' do
    it 'returns the correct ids' do
      ids = []
      cursor = { current_id: namespace_id, depth: [namespace_id] }

      iterator = described_class.new(namespace_class: namespace_class, cursor: cursor)
      iterator.each_batch(of: 5) do |batch_ids, new_cursor|
        ids.concat(batch_ids)
        cursor = new_cursor
      end

      iterator = described_class.new(namespace_class: namespace_class, cursor: cursor)
      iterator.each_batch(of: 500) do |batch_ids|
        ids.concat(batch_ids)
      end

      expect(collected_ids).to eq([
        group.id,
        subgroup1.id,
        subsubgroup1.id,
        subsubgroup2.id,
        project3.project_namespace_id,
        subsubgroup3.id,
        project4.project_namespace_id,
        project5.project_namespace_id,
        subgroup2.id,
        project1.project_namespace_id,
        project2.project_namespace_id
      ])
    end
  end

  context 'when querying a subgroup' do
    let(:namespace_id) { subgroup1.id }

    it 'returns the correct ids' do
      expect(collected_ids).to eq([
        subgroup1.id,
        subsubgroup1.id,
        subsubgroup2.id,
        project3.project_namespace_id,
        subsubgroup3.id,
        project4.project_namespace_id,
        project5.project_namespace_id
      ])
    end
  end

  context 'when querying a subgroup without descendants' do
    let(:namespace_id) { subgroup2.id }

    it 'finds only the given namespace id' do
      expect(collected_ids).to eq([subgroup2.id])
    end
  end

  context 'when batching over groups only' do
    let(:namespace_class) { Group }

    it 'returns the correct namespace ids' do
      expect(collected_ids).to eq([
        group.id,
        subgroup1.id,
        subsubgroup1.id,
        subsubgroup2.id,
        subsubgroup3.id,
        subgroup2.id
      ])
    end
  end

  context 'when the cursor is invalid' do
    context 'when non-integer current id is given' do
      it 'raises error' do
        cursor = { current_id: 'not int', depth: [group.id] }

        expect { collected_ids(cursor) }.to raise_error(ArgumentError)
      end
    end

    context 'when depth is not an array' do
      it 'raises error' do
        cursor = { current_id: group.id, depth: group.id }

        expect { collected_ids(cursor) }.to raise_error(ArgumentError)
      end
    end

    context 'when non-integer depth values are given' do
      it 'raises error' do
        cursor = { current_id: group.id, depth: ['not int'] }

        expect { collected_ids(cursor) }.to raise_error(ArgumentError)
      end
    end

    context 'when giving non-existing namespace id' do
      it 'returns nothing', :enable_admin_mode do
        cursor = { current_id: subgroup1.id, depth: [group.id, subgroup1.id] }

        Groups::DestroyService.new(group, user).execute

        expect(collected_ids(cursor)).to eq([])
      end
    end
  end
end

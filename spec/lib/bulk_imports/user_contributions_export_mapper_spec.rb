# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::UserContributionsExportMapper, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:group_1) { create(:group) }
  let_it_be(:cached_user_1) { create(:user) }
  let_it_be(:cached_user_2) { create(:user) }
  let_it_be(:non_cached_user_1) { create(:user) }
  let_it_be(:non_cached_user_2) { create(:user) }

  let(:cached_users) { [cached_user_1, cached_user_2] }
  let(:non_cached_users) { [non_cached_user_1, non_cached_user_2] }
  let(:group_1_cache_key) { "bulk_imports/#{group_1.class.name}/#{group_1.id}/user_contribution_ids" }

  subject(:user_contributions_export_mapper) { described_class.new(group_1) }

  describe '#cache_user_contributions_on_record' do
    shared_examples 'there are no references to cache' do
      it 'does not cache any user ids' do
        user_contributions_export_mapper.cache_user_contributions_on_record(record)

        expect(Gitlab::Cache::Import::Caching.values_from_set(group_1_cache_key)).to be_empty
      end
    end

    context 'when record is nil' do
      let(:record) { nil }

      it_behaves_like 'there are no references to cache'
    end

    context 'when record is a User' do
      let(:record) { create(:user) }

      it_behaves_like 'there are no references to cache'
    end

    context 'when record does not have references to a user' do
      let(:record) { create(:board) }

      it_behaves_like 'there are no references to cache'
    end

    context 'when record has references to a user' do
      let(:record) do
        create(
          :issue,
          author_id: non_cached_user_1.id,
          updated_by_id: non_cached_user_2.id,
          closed_by_id: cached_user_1.id,
          last_edited_by_id: cached_user_2.id
        )
      end

      before do
        Gitlab::Cache::Import::Caching.set_add(group_1_cache_key, cached_users.map(&:id))
      end

      it 'caches all user reference ids' do
        user_contributions_export_mapper.cache_user_contributions_on_record(record)

        all_cached_ids = (cached_users + non_cached_users).map { |user| user.id.to_s }

        expect(Gitlab::Cache::Import::Caching.values_from_set(group_1_cache_key)).to match_array(all_cached_ids)
      end

      it 'caches user_ids with a longer timeout to allow for longer exports' do
        all_cached_ids = (cached_users + non_cached_users).map(&:id)

        expect(Gitlab::Cache::Import::Caching).to receive(:set_add).with(
          group_1_cache_key, match_array(all_cached_ids), timeout: 72.hours.to_i
        )

        user_contributions_export_mapper.cache_user_contributions_on_record(record)
      end
    end
  end

  describe '#get_contributing_users' do
    it 'returns an ActiveRecord::Relation of users from the cached ids' do
      Gitlab::Cache::Import::Caching.set_add(group_1_cache_key, cached_users.map(&:id))

      expect(user_contributions_export_mapper.get_contributing_users.to_a).to match_array(cached_users)
    end

    it 'returns an empty relation if no users were cached' do
      empty_relation = user_contributions_export_mapper.get_contributing_users

      expect(empty_relation).to be_empty
    end
  end

  describe '#clear_cache' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group_2) { create(:group) }

    it 'clears the user contributions cache for the given portable' do
      Gitlab::Cache::Import::Caching.set_add(group_1_cache_key, cached_users.map(&:id))

      expect { user_contributions_export_mapper.clear_cache }.to change {
        user_contributions_export_mapper.get_contributing_users.count
      }.from(2).to(0)
    end

    it 'only clears the cache for matching portable class and id' do
      allow(project).to receive(:id).and_return(group_1.id)

      project_user_contributions_mapper = described_class.new(project)
      group_2_user_contributions_mapper = described_class.new(group_2)

      project_cache_key = "bulk_imports/#{project.class.name}/#{project.id}/user_contribution_ids"
      group_2_cache_key = "bulk_imports/#{group_2.class.name}/#{group_2.id}/user_contribution_ids"

      Gitlab::Cache::Import::Caching.set_add(project_cache_key, cached_users.map(&:id))
      Gitlab::Cache::Import::Caching.set_add(group_2_cache_key, cached_users.map(&:id))

      expect { user_contributions_export_mapper.clear_cache }
        .to not_change { project_user_contributions_mapper.get_contributing_users.count }
        .and not_change { group_2_user_contributions_mapper.get_contributing_users.count }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::UserContributionsExportService, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:group) }
  let_it_be(:cached_users) { create_list(:user, 2) }

  let(:jid) { 'jid' }

  subject(:service) { described_class.new(user.id, portable, jid) }

  describe '#execute' do
    shared_examples 'exports cached user contributions as a relation' do
      let(:cache_key) { "bulk_imports/#{portable.class.name}/#{portable.id}/user_contribution_ids" }

      before do
        Gitlab::Cache::Import::Caching.set_add(cache_key, cached_users.map(&:id))
      end

      it 'assigns cached contributing user ids to user_contributions attribute' do
        service.execute

        expect(portable.user_contributions.to_a).to match_array(cached_users)
      end

      it 'exports user_contributions as an unbatched relation' do
        service.execute

        user_contributions_export = portable.bulk_import_exports.find_by(relation: 'user_contributions')
        expect(user_contributions_export.batched).to eq(false)
      end

      it 'has a clear user id cache after export finishes' do
        service.execute

        expect(Gitlab::Cache::Import::Caching.values_from_set(cache_key)).to be_empty
      end
    end

    context 'when exporting a group' do
      it_behaves_like 'exports cached user contributions as a relation' do
        let!(:portable) { group }
      end
    end

    context 'when exporting a project' do
      it_behaves_like 'exports cached user contributions as a relation' do
        let!(:portable) { project }
      end
    end
  end
end

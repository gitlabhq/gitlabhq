# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'rendering namespace statistics', feature_category: :observability do
  include GraphqlHelpers

  let(:namespace) { user.namespace }
  let(:user) { create(:user) }
  let!(:statistics) do
    create(
      :namespace_root_storage_statistics,
      namespace: namespace,
      packages_size: 5.gigabytes,
      uploads_size: 3.gigabytes
    )
  end

  let(:query) do
    graphql_query_for(
      'namespace',
      { 'fullPath' => namespace.full_path },
      "rootStorageStatistics { #{all_graphql_fields_for('RootStorageStatistics')} }"
    )
  end

  shared_examples 'a working namespace with storage statistics query' do
    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: user)
      end
    end

    it 'includes the packages size if the user can read the statistics' do
      post_graphql(query, current_user: user)

      expect(graphql_data['namespace']['rootStorageStatistics']).not_to be_blank
      expect(graphql_data['namespace']['rootStorageStatistics']['packagesSize']).to eq(5.gigabytes)
    end

    it 'includes uploads size if the user can read the statistics' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:namespace, :root_storage_statistics, :uploads_size)).to eq(3.gigabytes)
    end
  end

  it_behaves_like 'a working namespace with storage statistics query'

  context 'when the namespace is a group' do
    let(:group) { create(:group) }
    let(:namespace) { group }

    before do
      group.add_owner(user)
    end

    it_behaves_like 'a working namespace with storage statistics query'

    context 'when the namespace is public' do
      let(:group) { create(:group, :public) }

      it 'hides statistics for unauthenticated requests' do
        post_graphql(query, current_user: nil)

        expect(graphql_data_at(:namespace, :root_storage_statistics)).to be_blank
      end
    end
  end
end

# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting dependency proxy manifests in a group', feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:manifest) { create(:dependency_proxy_manifest, group: group) }
  let_it_be(:manifest2) { create(:dependency_proxy_manifest, file_name: 'image2.json', group: group) }
  let_it_be(:manifests) { [manifest, manifest2].flatten }

  let(:dependency_proxy_manifest_fields) do
    <<~GQL
      edges {
        node {
          #{all_graphql_fields_for('dependency_proxy_manifests'.classify, max_depth: 1)}
        }
      }
    GQL
  end

  let(:fields) do
    <<~GQL
      #{query_graphql_field('dependency_proxy_manifests', {}, dependency_proxy_manifest_fields)}
      dependencyProxyImageCount
    GQL
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      fields
    )
  end

  let(:user) { owner }
  let(:variables) { {} }
  let(:dependency_proxy_manifests_response) { graphql_data.dig('group', 'dependencyProxyManifests', 'edges') }
  let(:dependency_proxy_image_count_response) { graphql_data.dig('group', 'dependencyProxyImageCount') }

  before do
    stub_config(dependency_proxy: { enabled: true })
    group.add_owner(owner)
  end

  subject { post_graphql(query, current_user: user, variables: variables) }

  it_behaves_like 'a working graphql query' do
    before do
      subject
    end
  end

  context 'with different permissions' do
    let_it_be(:user) { create(:user) }

    where(:group_visibility, :role, :access_granted) do
      :private | :maintainer | true
      :private | :developer  | true
      :private | :reporter   | true
      :private | :guest      | true
      :private | :anonymous  | false
      :public  | :maintainer | true
      :public  | :developer  | true
      :public  | :reporter   | true
      :public  | :guest      | true
      :public  | :anonymous  | false
    end

    with_them do
      before do
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.const_get(group_visibility.to_s.upcase, false))
        group.add_member(user, role) unless role == :anonymous
      end

      it 'return the proper response' do
        subject

        if access_granted
          expect(dependency_proxy_manifests_response.size).to eq(manifests.size)
        else
          expect(dependency_proxy_manifests_response).to be_blank
        end
      end
    end
  end

  context 'limiting the number of manifests' do
    let(:limit) { 1 }
    let(:variables) do
      { path: group.full_path, n: limit }
    end

    let(:query) do
      <<~GQL
        query($path: ID!, $n: Int) {
          group(fullPath: $path) {
            dependencyProxyManifests(first: $n) { #{dependency_proxy_manifest_fields} }
          }
        }
      GQL
    end

    it 'only returns N manifests' do
      subject

      expect(dependency_proxy_manifests_response.size).to eq(limit)
    end
  end

  it 'returns the total count of manifests' do
    subject

    expect(dependency_proxy_image_count_response).to eq(manifests.size)
  end

  describe 'sorting and pagination' do
    let(:data_path) { ['group', :dependencyProxyManifests] }
    let(:current_user) { owner }

    context 'with default sorting' do
      let_it_be(:descending_manifests) { manifests.reverse.map { |manifest| global_id_of(manifest) } }

      it_behaves_like 'sorted paginated query' do
        include_context 'no sort argument'

        let(:first_param) { 2 }
        let(:all_records) { descending_manifests.map(&:to_s) }
      end
    end

    def pagination_query(params)
      # remove sort since the type does not accept sorting, but be future proof
      graphql_query_for('group', { 'fullPath' => group.full_path },
        query_nodes(:dependencyProxyManifests, :id, include_pagination_info: true, args: params)
      )
    end
  end
end

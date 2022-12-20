# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting dependency proxy blobs in a group', feature_category: :dependency_proxy do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:blob) { create(:dependency_proxy_blob, group: group) }
  let_it_be(:blob2) { create(:dependency_proxy_blob, file_name: 'blob2.json', group: group) }
  let_it_be(:blobs) { [blob, blob2].flatten }

  let(:dependency_proxy_blob_fields) do
    <<~GQL
      edges {
        node {
          #{all_graphql_fields_for('dependency_proxy_blobs'.classify, max_depth: 1)}
        }
      }
    GQL
  end

  let(:fields) do
    <<~GQL
      #{query_graphql_field('dependency_proxy_blobs', {}, dependency_proxy_blob_fields)}
      dependencyProxyBlobCount
      dependencyProxyTotalSize
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
  let(:dependency_proxy_blobs_response) { graphql_data.dig('group', 'dependencyProxyBlobs', 'edges') }
  let(:dependency_proxy_blob_count_response) { graphql_data.dig('group', 'dependencyProxyBlobCount') }
  let(:dependency_proxy_total_size_response) { graphql_data.dig('group', 'dependencyProxyTotalSize') }

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
          expect(dependency_proxy_blobs_response.size).to eq(blobs.size)
        else
          expect(dependency_proxy_blobs_response).to be_blank
        end
      end
    end
  end

  context 'limiting the number of blobs' do
    let(:limit) { 1 }
    let(:variables) do
      { path: group.full_path, n: limit }
    end

    let(:query) do
      <<~GQL
        query($path: ID!, $n: Int) {
          group(fullPath: $path) {
            dependencyProxyBlobs(first: $n) { #{dependency_proxy_blob_fields} }
          }
        }
      GQL
    end

    it 'only returns N blobs' do
      subject

      expect(dependency_proxy_blobs_response.size).to eq(limit)
    end
  end

  it 'returns the total count of blobs' do
    subject

    expect(dependency_proxy_blob_count_response).to eq(blobs.size)
  end

  it 'returns the total size' do
    subject
    expected_size = blobs.inject(0) { |sum, blob| sum + blob.size }
    expect(dependency_proxy_total_size_response).to eq(ActiveSupport::NumberHelper.number_to_human_size(expected_size))
  end
end

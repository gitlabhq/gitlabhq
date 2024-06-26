# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query current user groups', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user) }
  let_it_be(:root_group) { create(:group, name: 'Root group', path: 'root-group', organization: organization) }
  let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest', guests: user, organization: organization) }
  let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer', parent: root_group, maintainers: user, organization: organization) }
  let_it_be(:public_developer_group) { create(:group, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer', developers: user, organization: organization) }
  let_it_be(:public_maintainer_group) { create(:group, name: 'a public maintainer', path: 'a-public-maintainer', parent: root_group, maintainers: user, organization: organization) }
  let_it_be(:public_owner_group) { create(:group, name: 'a public owner', path: 'a-public-owner', owners: user, organization: organization) }

  let(:group_arguments) { {} }
  let(:current_user) { user }

  let(:fields) do
    <<~GRAPHQL
      nodes { id path fullPath name }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('groups', group_arguments, fields))
  end

  subject { graphql_data.dig('currentUser', 'groups', 'nodes') }

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'avoids N+1 queries', :request_store do
    control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

    new_group = create(:group, :private, organization: organization)
    new_group.add_maintainer(current_user)

    expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
  end

  it 'returns all groups where the user is a direct member' do
    is_expected.to match(
      expected_group_hash(
        public_maintainer_group,
        public_owner_group,
        private_maintainer_group,
        public_developer_group,
        guest_group
      )
    )
  end

  context 'when permission_scope is CREATE_PROJECTS' do
    let(:group_arguments) { { permission_scope: :CREATE_PROJECTS } }

    specify do
      is_expected.to match(
        expected_group_hash(
          public_maintainer_group,
          public_owner_group,
          private_maintainer_group,
          public_developer_group
        )
      )
    end

    context 'when search is provided' do
      let(:group_arguments) { { permission_scope: :CREATE_PROJECTS, search: 'root-group maintainer' } }

      specify do
        is_expected.to match(
          expected_group_hash(
            public_maintainer_group,
            private_maintainer_group
          )
        )
      end
    end
  end

  context 'when permission_scope is TRANSFER_PROJECTS' do
    let(:group_arguments) { { permission_scope: :TRANSFER_PROJECTS } }

    specify do
      is_expected.to match(
        expected_group_hash(
          public_maintainer_group,
          public_owner_group,
          private_maintainer_group
        )
      )
    end

    context 'when search is provided' do
      let(:group_arguments) { { permission_scope: :TRANSFER_PROJECTS, search: 'owner' } }

      specify do
        is_expected.to match(
          expected_group_hash(
            public_owner_group
          )
        )
      end
    end
  end

  context 'when search is provided' do
    let(:group_arguments) { { search: 'maintainer' } }

    specify do
      is_expected.to match(
        expected_group_hash(
          public_maintainer_group,
          private_maintainer_group
        )
      )
    end

    context 'when searching for a full path (including parent)' do
      let(:group_arguments) { { search: 'root-group/b-private-maintainer' } }

      specify do
        is_expected.to match(
          expected_group_hash(
            private_maintainer_group
          )
        )
      end
    end
  end

  def expected_group_hash(*groups)
    groups.map do |group|
      {
        'id' => group.to_global_id.to_s,
        'name' => group.name,
        'path' => group.path,
        'fullPath' => group.full_path
      }
    end
  end
end

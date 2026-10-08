# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting custom emoji within namespace', feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private, developers: current_user) }
  let_it_be(:custom_emoji) { create(:custom_emoji, group: group, file: 'http://example.com/test.png') }

  describe "Query CustomEmoji on Group" do
    def custom_emoji_query(group)
      fields = all_graphql_fields_for('Group')
      # TODO: Set required timelogs args elsewhere https://gitlab.com/gitlab-org/gitlab/-/issues/325499
      fields.selection['timelogs(startDate: "2021-03-01" endDate: "2021-03-30")'] = fields.selection.delete('timelogs')

      graphql_query_for(
        'group',
        { fullPath: group.full_path },
        fields
      )
    end

    it 'returns emojis when authorised' do
      post_graphql(custom_emoji_query(group), current_user: current_user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(graphql_data['group']['customEmoji']['nodes'].count).to eq(1)
      expect(graphql_data['group']['customEmoji']['nodes'].first['name']).to eq(custom_emoji.name)
      expect(graphql_data['group']['customEmoji']['nodes'].first['url']).to eq(custom_emoji.file)
    end

    it 'returns nil group when unauthorised' do
      user = create(:user)
      post_graphql(custom_emoji_query(group), current_user: user)

      expect(graphql_data['group']).to be_nil
    end

    describe 'granular PAT authorization' do
      let(:query) do
        graphql_query_for(
          'group',
          { fullPath: group.full_path },
          query_graphql_field('customEmoji', {}, 'count nodes { name }')
        )
      end

      it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_group, :read_custom_emoji] do
        let(:user) { current_user }
        let(:boundary_object) { group }
        let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
      end

      it 'returns no emojis for a granular token without read_custom_emoji' do
        assignable = ::Authz::PermissionGroups::Assignable.for_permission(:read_group).first.name
        pat = create(:granular_pat, user: current_user, boundary: ::Authz::Boundary.for(group),
          permissions: [assignable])

        post_graphql(query, token: { personal_access_token: pat })

        expect(graphql_data_at(:group, :custom_emoji, :nodes)).to eq([])
      end

      it 'returns the emojis for a granular token with read_custom_emoji' do
        assignables = [:read_group, :read_custom_emoji].map do |permission|
          ::Authz::PermissionGroups::Assignable.for_permission(permission).first.name
        end
        pat = create(:granular_pat, user: current_user, boundary: ::Authz::Boundary.for(group),
          permissions: assignables)

        post_graphql(query, token: { personal_access_token: pat })

        expect(graphql_data_at(:group, :custom_emoji, :nodes)).to eq([{ 'name' => custom_emoji.name }])
      end
    end

    context 'when asset proxy is configured' do
      before do
        stub_asset_proxy_enabled(
          url: 'https://assets.example.com',
          secret_key: 'shared-secret',
          allowlist: []
        )
      end

      it 'uses the proxied url' do
        post_graphql(custom_emoji_query(group), current_user: current_user)
        expect(graphql_data['group']['customEmoji']['nodes'].first['url']).to start_with('https://assets.example.com')
      end
    end
  end
end

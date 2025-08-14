# frozen_string_literal: true

RSpec.shared_context 'with work items list request' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:reporter) { create(:user, reporter_of: [group, project]) }
  let_it_be(:current_user) { user }

  let(:item_filter_params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workItems'.classify, max_depth: 2)}
      }
    QUERY
  end
end

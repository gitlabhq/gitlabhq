# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting group label information' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:label_factory) { :group_label }
  let_it_be(:label_attrs) { { group: group } }

  it_behaves_like 'querying a GraphQL type with labels' do
    let(:path_prefix) { ['group'] }

    def make_query(fields)
      graphql_query_for('group', { full_path: group.full_path }, fields)
    end
  end
end

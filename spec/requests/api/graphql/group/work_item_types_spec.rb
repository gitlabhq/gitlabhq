# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of work item types for a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  it_behaves_like 'graphql work item type list request spec' do
    let(:current_user) { developer }
    let(:parent) { group }

    it_behaves_like 'allowed work item types for a group' do
      let(:resource_parent) { parent }

      subject(:types_list) do
        post_graphql(query, current_user: current_user)

        graphql_data_at(parent_key, :workItemTypes, :nodes).map do |type|
          # the shared example expects a list of basic types
          type['name'].downcase.tr(' ', '_')
        end
      end
    end
  end
end

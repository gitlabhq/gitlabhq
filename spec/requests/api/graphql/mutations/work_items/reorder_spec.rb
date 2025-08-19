# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reorder work items', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:item1, reload: true) { create(:work_item, :issue, project: project, relative_position: 10) }
  let_it_be(:item2, reload: true) { create(:work_item, :issue, project: project, relative_position: 20) }
  let_it_be(:item3, reload: true) { create(:work_item, :issue, project: project, relative_position: 20) }

  let(:input) do
    {
      id: item1.to_gid.to_s
    }
  end

  let(:mutation) { graphql_mutation(:work_items_reorder, input) }
  let(:mutation_response) { graphql_mutation_response(:work_items_reorder) }

  context 'when missing arguments' do
    let(:input) do
      {
        id: item1.to_gid.to_s
      }
    end

    it 'returns an error' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { item1.relative_position }

      expect_graphql_errors_to_include(
        'At least one of move_before_id and move_after_id are required'
      )
    end
  end

  context 'when all arguments are given' do
    context 'when moving it before other item' do
      let(:input) do
        {
          id: item1.to_gid.to_s,
          move_before_id: item2.to_gid.to_s
        }
      end

      specify do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { item1.reload.relative_position }.to be > item2.relative_position

        expect(graphql_errors).to be_blank
        expect(mutation_response['errors']).to be_blank
      end
    end

    context 'when moving it after other item' do
      let(:input) do
        {
          id: item2.to_gid.to_s,
          move_after_id: item1.to_gid.to_s
        }
      end

      specify do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { item2.reload.relative_position }.to be < item1.relative_position

        expect(graphql_errors).to be_blank
        expect(mutation_response['errors']).to be_blank
      end
    end
  end
end

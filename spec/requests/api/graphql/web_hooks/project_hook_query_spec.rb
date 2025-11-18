# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying for a project hook', feature_category: :webhooks do
  include GraphqlHelpers

  let_it_be(:project_hook) { create(:project_hook) }
  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project_hook.project.full_path },
      <<~GRAPHQL
        webhook(id: "#{GitlabSchema.id_from_object(project_hook)}") {
          id
        }
      GRAPHQL
    )
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when the user is authorized' do
    before_all do
      project_hook.project.add_maintainer(current_user)
    end

    it 'returns the project hook' do
      response_id = graphql_data_at('project', 'webhook', 'id')

      expect(response_id).to eq(global_id_of(project_hook).to_s)
    end
  end

  context 'when the user is not authorized' do
    before_all do
      project_hook.project.add_developer(current_user)
    end

    it 'does not return the project hook' do
      response_id = graphql_data_at('project', 'webhook')

      expect(response_id).to be_nil
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying for webhook events', feature_category: :webhooks do
  include GraphqlHelpers

  before do
    post_graphql(query, current_user: current_user)
  end

  describe 'webhook events on a project hook' do
    let_it_be(:project_hook) { create(:project_hook) }
    let_it_be(:user) { create(:user) }
    let_it_be(:current_user) { user }
    let_it_be(:webhook_events) { create_list(:web_hook_log, 5, web_hook: project_hook) }

    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project_hook.project.full_path },
        <<~GRAPHQL
          webhook(id: "#{GitlabSchema.id_from_object(project_hook)}") {
            webhookEvents {
              nodes {
                id
              }
            }
          }
        GRAPHQL
      )
    end

    context 'when the user is authorized' do
      before_all do
        project_hook.project.add_maintainer(current_user)
      end

      it 'returns webhook events' do
        response_ids = graphql_data_at('project', 'webhook', 'webhookEvents', 'nodes', 'id')
        expected_ids = project_hook.web_hook_logs.map { |web_hook_log| GitlabSchema.id_from_object(web_hook_log).to_s }

        expect(response_ids).to match_array(expected_ids)
      end
    end

    context 'when the user is not authorized' do
      before_all do
        project_hook.project.add_developer(current_user)
      end

      it 'does not return webhook events' do
        response_id = graphql_data_at('project', 'webhook', 'webhookEvents')

        expect(response_id).to be_nil
      end
    end
  end
end

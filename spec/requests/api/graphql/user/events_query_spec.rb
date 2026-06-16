# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting events of a user', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be_with_reload(:target_user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let_it_be(:push_event) { create(:push_event, project: project, author: target_user) }
  let_it_be(:merge_event) do
    create(:event, :merged,
      project: project,
      author: target_user,
      target: create(:merge_request, source_project: project))
  end

  let_it_be(:issue_event) do
    create(:event, :created,
      project: project,
      author: target_user,
      target: create(:issue, project: project))
  end

  let_it_be(:comment_event) do
    create(:event, :commented,
      project: project,
      author: target_user,
      target: create(:note, project: project))
  end

  let_it_be(:path) { %i[user events nodes] }

  let(:user_params) { { username: target_user.username } }
  let(:query) { graphql_query_for(:user, user_params, query_nodes(:events, :id)) }

  let(:events) do
    post_graphql(query, current_user: current_user)

    graphql_data_at(*path)
  end

  context 'when the target user profile is readable' do
    let(:current_user) { target_user }

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'returns the events authored by the target user' do
      expect(events).to contain_exactly(
        a_graphql_entity_for(push_event),
        a_graphql_entity_for(merge_event),
        a_graphql_entity_for(issue_event),
        a_graphql_entity_for(comment_event)
      )
    end

    it 'returns the events with the most recent first' do
      expect(events.pluck('id')).to eq(
        [comment_event, issue_event, merge_event, push_event].map { |event| event.to_global_id.to_s }
      )
    end

    context 'when filtering by event type' do
      using RSpec::Parameterized::TableSyntax

      where(:filter, :expected_event) do
        :PUSH     | ref(:push_event)
        :MERGED   | ref(:merge_event)
        :ISSUE    | ref(:issue_event)
        :COMMENTS | ref(:comment_event)
      end

      with_them do
        it 'returns only the events matching the filter' do
          filtered_query = graphql_query_for(:user, user_params, query_nodes(:events, :id, args: { filter: filter }))

          post_graphql(filtered_query, current_user: current_user)

          expect(graphql_data_at(*path)).to contain_exactly(a_graphql_entity_for(expected_event))
        end
      end
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      fields = 'id action author { id } project { id }'
      events_query = graphql_query_for(:user, user_params, query_nodes(:events, fields))

      post_graphql(events_query, current_user: current_user)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(events_query, current_user: current_user)
      end

      create(:event, :closed,
        project: project,
        author: target_user,
        target: create(:issue, project: project))

      expect do
        post_graphql(events_query, current_user: current_user)
      end.not_to exceed_all_query_limit(control)
    end
  end

  context 'when the target user profile is private' do
    let(:current_user) { create(:user) }

    before do
      target_user.update!(private_profile: true)
    end

    it 'returns no events' do
      expect(events).to be_empty
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace.sidebar', feature_category: :navigation do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }

  let_it_be(:reporter) { create(:user, reporter_of: group) }

  let(:query) do
    <<~QUERY
    query {
      namespace(fullPath: "#{namespace.full_path}") {
        sidebar {
          openIssuesCount
          openMergeRequestsCount
        }
      }
    }
    QUERY
  end

  before_all do
    create_list(:issue, 2, project: project)
    create(:merge_request, source_project: project)
  end

  context 'with a Group' do
    let(:namespace) { group }

    it 'returns the group counts' do
      post_graphql(query, current_user: reporter)

      expect(response).to have_gitlab_http_status(:ok)

      expect(graphql_data_at(:namespace, :sidebar)).to eq({
        'openIssuesCount' => 2,
        'openMergeRequestsCount' => 1
      })
    end

    context 'when issue count query times out' do
      before do
        allow_next_instance_of(::Groups::OpenIssuesCountService) do |service|
          allow(service).to receive(:count).and_raise(ActiveRecord::QueryCanceled)
        end
      end

      it 'logs the error and returns a null issue count' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          ActiveRecord::QueryCanceled, group_id: namespace.id, query: 'group_sidebar_issues_count'
        ).and_call_original

        post_graphql(query, current_user: reporter)

        expect(response).to have_gitlab_http_status(:ok)

        expect(graphql_data_at(:namespace, :sidebar)).to eq({
          'openIssuesCount' => nil,
          'openMergeRequestsCount' => 1
        })
      end
    end
  end

  context 'with a ProjectNamespace' do
    let(:namespace) { project.project_namespace }

    it 'returns the project counts' do
      post_graphql(query, current_user: reporter)

      expect(response).to have_gitlab_http_status(:ok)

      expect(graphql_data_at(:namespace, :sidebar)).to eq({
        'openIssuesCount' => 2,
        'openMergeRequestsCount' => 1
      })
    end
  end
end

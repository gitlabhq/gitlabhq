# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recent items logging for namespace work items', feature_category: :team_planning do
  include GraphqlHelpers

  let(:query_work_item) { work_item }
  let(:query) do
    graphql_query_for(
      'namespace',
      { 'fullPath' => namespace.full_path },
      query_graphql_field('workItem', { 'iid' => query_work_item.iid.to_s }, 'id iid title')
    )
  end

  shared_examples 'logs recent view for supported work item types' do
    context 'when work item is supported for recent items logging' do
      it 'logs the work item to recent items' do
        recent_service = instance_double(expected_service_class)
        expect(expected_service_class).to receive(:new).with(user: user).and_return(recent_service)
        expect(recent_service).to receive(:log_view).with(work_item)

        post_graphql(query, current_user: user)

        expect(graphql_errors).to be_blank
        expect(graphql_data_at(:namespace, :workItem)).to include('id' => work_item.to_gid.to_s)
      end
    end

    context 'when current_user is nil' do
      it 'does not log to recent items' do
        expect(expected_service_class).not_to receive(:new)

        post_graphql(query, current_user: nil)

        expect(graphql_errors).to be_blank
        # Work item is still returned for public namespaces, but recent items logging is skipped
        expect(graphql_data_at(:namespace, :workItem)).to include('id' => work_item.to_gid.to_s)
      end
    end

    context 'when work item does not exist' do
      let(:query) do
        graphql_query_for(
          'namespace',
          { 'fullPath' => namespace.full_path },
          query_graphql_field('workItem', { 'iid' => '99999' }, 'id iid title')
        )
      end

      it 'does not log to recent items' do
        expect(expected_service_class).not_to receive(:new)

        post_graphql(query, current_user: user)

        expect(graphql_errors).to be_blank
        expect(graphql_data_at(:namespace, :workItem)).to be_nil
      end
    end
  end

  shared_examples 'does not log for unsupported work item types' do
    it 'does not log to recent items' do
      expect(::Gitlab::Search::RecentIssues).not_to receive(:new)
      expect(::Gitlab::Search::RecentEpics).not_to receive(:new) if defined?(::Gitlab::Search::RecentEpics)

      post_graphql(query, current_user: user)

      expect(graphql_errors).to be_blank
      expect(graphql_data_at(:namespace, :workItem)).to include('id' => work_item.to_gid.to_s)
    end
  end

  describe 'recent items logging' do
    context 'with project namespace' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:user) { create(:user, developer_of: project) }
      let_it_be(:issue_work_item) { create(:work_item, :issue, project: project) }
      let_it_be(:task_work_item) { create(:work_item, :task, project: project) }

      let(:namespace) { project }

      context 'when work item is an issue' do
        let(:work_item) { issue_work_item }
        let(:expected_service_class) { ::Gitlab::Search::RecentIssues }

        include_examples 'logs recent view for supported work item types'
      end

      context 'when work item is a task (unsupported type)' do
        let(:work_item) { task_work_item }

        include_examples 'does not log for unsupported work item types'
      end
    end
  end
end

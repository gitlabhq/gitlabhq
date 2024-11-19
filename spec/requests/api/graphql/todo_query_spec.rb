# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Todo Query', feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:current_user) { nil }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let_it_be(:todo_owner) { create(:user, developer_of: project) }

  let_it_be(:todo) { create(:todo, user: todo_owner, target: issue) }

  let(:todo_subject) { todo }

  let(:fields) do
    <<~GRAPHQL
      id
      targetType
      target {
        webUrl
        ... on WorkItem {
          id
        }
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for(:todo, { id: todo_subject.to_global_id.to_s }, fields)
  end

  subject(:graphql_response) do
    result = GitlabSchema.execute(query, context: { current_user: current_user }).to_h
    graphql_dig_at(result, :data, :todo)
  end

  context 'when requesting user is todo owner' do
    let(:current_user) { todo_owner }

    it { is_expected.to include('id' => todo_subject.to_global_id.to_s) }

    context 'when todo target is WorkItem' do
      let(:work_item) { create(:work_item, :task, project: project) }
      let(:todo_subject) { create(:todo, user: todo_owner, target: work_item, target_type: WorkItem.name) }

      it 'works with a WorkItem target' do
        expect(graphql_response).to include(
          'id' => todo_subject.to_gid.to_s,
          'targetType' => 'WORKITEM',
          'target' => {
            'id' => work_item.to_gid.to_s,
            'webUrl' => Gitlab::UrlBuilder.build(work_item)
          }
        )
      end
    end
  end

  context 'when requesting user is not todo owner' do
    let(:current_user) { create(:user) }

    it { is_expected.to be_nil }
  end

  context 'when unauthenticated' do
    it { is_expected.to be_nil }
  end
end

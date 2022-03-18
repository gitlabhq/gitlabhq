# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.work_item(id)' do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :private).tap { |project| project.add_developer(developer) } }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:current_user) { developer }
  let(:work_item_data) { graphql_data['workItem'] }
  let(:work_item_fields) { all_graphql_fields_for('WorkItem') }
  let(:global_id) { work_item.to_gid.to_s }

  let(:query) do
    graphql_query_for('workItem', { 'id' => global_id }, work_item_fields)
  end

  context 'when the user can read the work item' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns all fields' do
      expect(work_item_data).to include(
        'description' => work_item.description,
        'id' => work_item.to_gid.to_s,
        'iid' => work_item.iid.to_s,
        'lockVersion' => work_item.lock_version,
        'state' => "OPEN",
        'title' => work_item.title,
        'workItemType' => hash_including('id' => work_item.work_item_type.to_gid.to_s)
      )
    end

    context 'when an Issue Global ID is provided' do
      let(:global_id) { Issue.find(work_item.id).to_gid.to_s }

      it 'allows an Issue GID as input' do
        expect(work_item_data).to include('id' => work_item.to_gid.to_s)
      end
    end
  end

  context 'when the user can not read the work item' do
    let(:current_user) { create(:user) }

    before do
      post_graphql(query)
    end

    it 'returns an access error' do
      expect(work_item_data).to be_nil
      expect(graphql_errors).to contain_exactly(
        hash_including('message' => ::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      )
    end
  end

  context 'when the work_items feature flag is disabled' do
    before do
      stub_feature_flags(work_items: false)
    end

    it 'returns nil' do
      post_graphql(query)

      expect(work_item_data).to be_nil
    end
  end
end

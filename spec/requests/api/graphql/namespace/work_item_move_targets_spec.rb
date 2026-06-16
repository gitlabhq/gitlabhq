# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace.workItemMoveTargets', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:source_group) { create(:group, developers: current_user) }
  let_it_be(:target_group) { create(:group, developers: current_user) }
  let_it_be(:source_project) { create(:project, group: source_group) }
  let_it_be(:target_project) { create(:project, group: target_group) }

  let(:provider) { WorkItems::TypesFramework::Provider.new(source_project.project_namespace) }
  let(:issue_type) { provider.find_by_base_type(:issue) }
  let(:issue_gid) { issue_type.to_gid.to_s }

  let(:query) do
    <<~GQL
      query($targetPath: ID!, $sourcePath: String!, $sourceIds: [WorkItemsTypeID!]!) {
        namespace(fullPath: $targetPath) {
          workItemMoveTargets(sourceFullPath: $sourcePath, sourceTypeIds: $sourceIds) {
            sourceType { id name }
            suggestedTargetType { id name }
            validTargetTypes { id name }
          }
        }
      }
    GQL
  end

  let(:variables) do
    {
      targetPath: target_project.full_path,
      sourcePath: source_project.full_path,
      sourceIds: [issue_gid]
    }
  end

  before do
    post_graphql(query, current_user: current_user, variables: variables)
  end

  it 'returns one result for the source Issue with itself suggested', :aggregate_failures do
    results = graphql_data.dig('namespace', 'workItemMoveTargets')

    expect(results).to be_an(Array)
    expect(results.size).to eq(1)

    first = results.first
    expect(first['sourceType']['id']).to eq(issue_gid)
    expect(first['suggestedTargetType']['id']).to eq(issue_gid)
    expect(first['validTargetTypes'].pluck('id')).to include(issue_gid)
  end

  context 'when the source namespace cannot be resolved' do
    let(:variables) do
      {
        targetPath: target_project.full_path,
        sourcePath: 'does/not/exist',
        sourceIds: [issue_gid]
      }
    end

    it 'returns a resource not available error', :aggregate_failures do
      expect(graphql_data.dig('namespace', 'workItemMoveTargets')).to be_nil
      expect(graphql_errors.first['message'])
        .to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
    end
  end

  context 'when current_user cannot read the source namespace' do
    let_it_be(:private_source_group) { create(:group, :private) }
    let_it_be(:private_source_project) { create(:project, :private, group: private_source_group) }

    let(:variables) do
      {
        targetPath: target_project.full_path,
        sourcePath: private_source_project.full_path,
        sourceIds: [issue_gid]
      }
    end

    it 'returns a resource not available error, indistinguishable from a missing namespace', :aggregate_failures do
      expect(graphql_data.dig('namespace', 'workItemMoveTargets')).to be_nil
      expect(graphql_errors.first['message'])
        .to eq(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
    end
  end

  context 'when too many source type ids are provided' do
    let(:max_ids) { Resolvers::WorkItems::MoveTargetsResolver::MAX_SOURCE_TYPES }
    let(:variables) do
      {
        targetPath: target_project.full_path,
        sourcePath: source_project.full_path,
        sourceIds: Array.new(max_ids + 1) { |i| "gid://gitlab/WorkItems::Type/#{i + 1}" }
      }
    end

    it 'returns an argument error', :aggregate_failures do
      expect(graphql_errors).to be_present
      expect(graphql_errors.first['message']).to match(/No more than #{max_ids} source work item types/)
    end
  end
end

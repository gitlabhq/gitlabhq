# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.workItemTypes.unavailableWidgetsOnConversion', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user, developer_of: group) }

  let_it_be(:source_type) { build(:work_item_system_defined_type, :ticket) }
  let_it_be(:target_type) { build(:work_item_system_defined_type, :incident) }

  let(:query) do
    <<~QUERY
      query {
        project(fullPath: "#{project.full_path}") {
          workItemTypes {
            nodes {
              id
              name
              unavailableWidgetsOnConversion(
                target: "#{target_type.to_gid}"
              ) {
                type
              }
            }
          }
        }
      }
    QUERY
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns widgets lost on conversion for work item types' do
    work_item_types = graphql_data.dig('project', 'workItemTypes', 'nodes')

    expect(work_item_types).to be_present

    # Find the source type that has the widgets we expect to be lost
    source_type_node = work_item_types.find { |type| type['id'] == source_type.to_gid.to_s }
    expect(source_type_node).to be_present

    widgets_lost = source_type_node['unavailableWidgetsOnConversion']
    expect(widgets_lost).to be_an(Array)
    expect(widgets_lost.size).to eq(2)

    widget_types = widgets_lost.pluck('type')
    expect(widget_types).to contain_exactly("DESIGNS", "START_AND_DUE_DATE")

    expect(widgets_lost).to all(have_key('type'))
  end

  context 'when user does not have permission' do
    let(:current_user) { create(:user) }

    it 'returns null for project' do
      expect(graphql_data['project']).to be_nil
    end
  end

  context 'with invalid target work item type' do
    let(:query) do
      <<~QUERY
        query {
          project(fullPath: "#{project.full_path}") {
            workItemTypes {
              nodes {
                id
                name
                unavailableWidgetsOnConversion(
                  target: "gid://gitlab/WorkItems::Type/999999"
                ) {
                  type
                }
              }
            }
          }
        }
      QUERY
    end

    it 'returns empty array for widgets lost on conversion' do
      work_item_types = graphql_data.dig('project', 'workItemTypes', 'nodes')

      work_item_types.each do |type|
        expect(type['unavailableWidgetsOnConversion']).to be_empty
      end
    end
  end
end

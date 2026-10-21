# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.workItem hierarchy widget authorization', :with_current_organization,
  feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:public_project) { create(:project, :public, group: public_group) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:private_project) { create(:project, :private, group: private_group) }

  let_it_be(:public_parent_work_item) { create(:work_item, project: public_project) }
  let_it_be(:public_child_work_item) { create(:work_item, :task, project: public_project) }
  let_it_be(:public_confidential_sibling) do
    create(:work_item, :task, confidential: true, project: public_project, title: 'confidential sibling')
  end

  let_it_be(:parent_link) do
    create(:parent_link, work_item_parent: public_parent_work_item, work_item: public_child_work_item)
  end

  let(:current_user) { nil }

  describe 'children -> namespace -> workItem(iid:) traversal' do
    let(:query) do
      graphql_query_for(
        'workItem',
        { 'id' => public_parent_work_item.to_gid.to_s },
        <<~FIELDS
          widgets {
            ... on WorkItemWidgetHierarchy {
              children {
                nodes {
                  namespace {
                    workItem(iid: "#{public_confidential_sibling.iid}") {
                      id
                      title
                    }
                  }
                }
              }
            }
          }
        FIELDS
      )
    end

    context 'when the requester is anonymous' do
      it 'does not disclose confidential work items in the same namespace' do
        post_graphql(query, current_user: current_user)

        child_node = graphql_data.dig('workItem', 'widgets')
          .find { |w| w.key?('children') }
          &.dig('children', 'nodes', 0)

        expect(child_node).to be_present
        expect(child_node.dig('namespace', 'workItem')).to be_nil
      end
    end

    context 'when the requester is a non-member user' do
      let(:current_user) { create(:user) }

      it 'does not disclose confidential work items in the same namespace' do
        post_graphql(query, current_user: current_user)

        child_node = graphql_data.dig('workItem', 'widgets')
          .find { |w| w.key?('children') }
          &.dig('children', 'nodes', 0)

        expect(child_node).to be_present
        expect(child_node.dig('namespace', 'workItem')).to be_nil
      end
    end
  end

  describe 'ancestors -> namespace -> workItem(iid:) traversal' do
    let(:query) do
      graphql_query_for(
        'workItem',
        { 'id' => public_child_work_item.to_gid.to_s },
        <<~FIELDS
          widgets {
            ... on WorkItemWidgetHierarchy {
              ancestors {
                nodes {
                  namespace {
                    workItem(iid: "#{public_confidential_sibling.iid}") {
                      id
                      title
                    }
                  }
                }
              }
            }
          }
        FIELDS
      )
    end

    context 'when the requester is anonymous' do
      it 'does not disclose confidential work items in the same namespace' do
        post_graphql(query, current_user: current_user)

        ancestors_nodes = graphql_data.dig(
          'workItem', 'widgets'
        ).find { |w| w.key?('ancestors') }&.dig('ancestors', 'nodes') || []

        expect(ancestors_nodes).not_to be_empty
        ancestors_nodes.each do |node|
          expect(node.dig('namespace', 'workItem')).to be_nil
        end
      end
    end
  end

  describe 'private ancestor work item is not disclosed through ancestors field' do
    let_it_be(:private_ancestor_work_item) do
      create(:work_item, project: private_project, title: 'private ancestor title',
        description: 'private ancestor description')
    end

    let_it_be(:public_orphan_child_work_item) { create(:work_item, :task, project: public_project) }

    let_it_be(:cross_namespace_link) do
      create(:parent_link, work_item_parent: private_ancestor_work_item, work_item: public_orphan_child_work_item)
    end

    let(:query) do
      graphql_query_for(
        'workItem',
        { 'id' => public_orphan_child_work_item.to_gid.to_s },
        <<~FIELDS
          widgets {
            ... on WorkItemWidgetHierarchy {
              ancestors {
                nodes {
                  id
                  title
                  description
                }
              }
            }
          }
        FIELDS
      )
    end

    context 'when the requester is anonymous' do
      it 'does not include the private ancestor in the ancestors list' do
        post_graphql(query, current_user: current_user)

        ancestors_widget = graphql_data.dig(
          'workItem', 'widgets'
        ).find { |w| w.key?('ancestors') }

        ancestor_ids = (ancestors_widget&.dig('ancestors', 'nodes') || []).pluck('id')
        expect(ancestor_ids).not_to include(private_ancestor_work_item.to_gid.to_s)
      end
    end
  end

  describe 'authorized user still sees permitted hierarchy relationships' do
    let(:developer) { create(:user, developer_of: public_project) }

    let(:query) do
      graphql_query_for(
        'workItem',
        { 'id' => public_parent_work_item.to_gid.to_s },
        <<~FIELDS
          widgets {
            ... on WorkItemWidgetHierarchy {
              children {
                nodes {
                  id
                }
              }
            }
          }
        FIELDS
      )
    end

    it 'returns the child work item' do
      post_graphql(query, current_user: developer)

      children_widget = graphql_data.dig(
        'workItem', 'widgets'
      ).find { |w| w.key?('children') }

      child_ids = children_widget.dig('children', 'nodes').pluck('id')
      expect(child_ids).to include(public_child_work_item.to_gid.to_s)
    end
  end
end

# frozen_string_literal: true

RSpec.shared_context 'with work item types request context' do
  let(:work_item_type_fields) do
    <<~GRAPHQL
      id
      name
      iconName
      widgetDefinitions {
        type
        ... on WorkItemWidgetDefinitionAssignees {
          canInviteMembers
        }
        ... on WorkItemWidgetDefinitionHierarchy {
          allowedChildTypes {
            nodes { id name }
          }
          allowedParentTypes {
            nodes { id name }
          }
        }
      }
    GRAPHQL
  end

  # This is necessary so we can overwrite attributes in EE
  let(:widget_attributes) { base_widget_attributes }
  let(:base_widget_attributes) do
    {
      assignees: {
        'canInviteMembers' => false
      }
    }
  end

  def expected_work_item_type_response(resource_parent, work_item_type = nil)
    base_scope = WorkItems::Type.default
    base_scope = base_scope.id_in(work_item_type.id) if work_item_type

    base_scope.map do |type|
      hash_including(
        'id' => type.to_global_id.to_s,
        'name' => type.name,
        'iconName' => type.icon_name,
        'widgetDefinitions' => match_array(widgets_for(type, resource_parent))
      )
    end
  end

  def widgets_for(work_item_type, resource_parent)
    work_item_type.widget_classes(resource_parent).map do |widget|
      base_attributes = { 'type' => widget.type.to_s.upcase }
      next hierarchy_widget_attributes(work_item_type, base_attributes) if widget == WorkItems::Widgets::Hierarchy
      next base_attributes unless widget_attributes[widget.type]

      base_attributes.merge(widget_attributes[widget.type])
    end
  end

  def hierarchy_widget_attributes(work_item_type, base_attributes)
    child_types = work_item_type.allowed_child_types_by_name.map do |child_type|
      { "id" => child_type.to_global_id.to_s, "name" => child_type.name }
    end
    parent_types = work_item_type.allowed_parent_types_by_name.map do |parent_type|
      { "id" => parent_type.to_global_id.to_s, "name" => parent_type.name }
    end

    base_attributes.merge({ 'allowedChildTypes' => { 'nodes' => child_types },
'allowedParentTypes' => { 'nodes' => parent_types } })
  end
end

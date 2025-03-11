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
        ... on WorkItemWidgetDefinitionStatus {
          allowedStatuses {
            nodes { id name iconName color position }
          }
        }
      }
      supportedConversionTypes {
        id
        name
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

  def expected_work_item_type_response(resource_parent, user, work_item_type = nil)
    base_scope = WorkItems::Type.all
    base_scope = base_scope.id_in(work_item_type.id) if work_item_type

    base_scope.map do |type|
      hash_including(
        'id' => type.to_global_id.to_s,
        'name' => type.name,
        'iconName' => type.icon_name,
        'widgetDefinitions' => match_array(widgets_for(type, resource_parent)),
        'supportedConversionTypes' => type.supported_conversion_types(resource_parent, user).map do |conversion_type|
          {
            'id' => conversion_type.to_global_id.to_s,
            'name' => conversion_type.name
          }
        end
      )
    end
  end

  def widgets_for(work_item_type, resource_parent)
    work_item_type.widget_classes(resource_parent).map do |widget|
      base_attributes = { 'type' => widget.type.to_s.upcase }

      if widget == WorkItems::Widgets::Hierarchy
        next hierarchy_widget_attributes(work_item_type, base_attributes, resource_parent)
      end

      if widget == WorkItems::Widgets::Status
        next status_widget_attributes(work_item_type,
          base_attributes, resource_parent)
      end

      next base_attributes unless widget_attributes[widget.type]

      base_attributes.merge(widget_attributes[widget.type])
    end
  end

  def hierarchy_widget_attributes(work_item_type, base_attributes, resource_parent)
    child_types =
      work_item_type.allowed_child_types(authorize: true, resource_parent: resource_parent).map do |child_type|
        { "id" => child_type.to_global_id.to_s, "name" => child_type.name }
      end

    parent_types =
      work_item_type.allowed_parent_types(authorize: true, resource_parent: resource_parent).map do |parent_type|
        { "id" => parent_type.to_global_id.to_s, "name" => parent_type.name }
      end

    base_attributes
      .merge({ 'allowedChildTypes' => { 'nodes' => child_types }, 'allowedParentTypes' => { 'nodes' => parent_types } })
  end

  def status_widget_attributes(_work_item_type, base_attributes, resource_parent)
    unless resource_parent&.root_ancestor&.try(:work_item_status_feature_available?)
      return base_attributes.merge({ 'allowedStatuses' => { 'nodes' => [] } })
    end

    statuses = [
      {
        'id' => 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
        'name' => 'To do',
        'iconName' => 'status-waiting',
        'color' => '#535158',
        'position' => 0
      },
      {
        'id' => 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
        'name' => 'In progress',
        'iconName' => 'status-running',
        'color' => '#0b5cad',
        'position' => 0
      },
      {
        'id' => 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/3',
        'name' => 'Done',
        'iconName' => 'status-success',
        'color' => '#23663b',
        'position' => 0
      },
      {
        'id' => 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/4',
        'name' => "Won't do",
        'iconName' => 'status-cancelled',
        'color' => '#ae1901',
        'position' => 0
      },
      {
        'id' => 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/5',
        'name' => 'Duplicate',
        'iconName' => 'status-cancelled',
        'color' => '#ae1901',
        'position' => 10
      }
    ]

    base_attributes.merge({ 'allowedStatuses' => { 'nodes' => statuses } })
  end
end

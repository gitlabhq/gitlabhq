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
      }
    GRAPHQL
  end

  let(:widget_attributes) do
    {
      assignees: {
        'canInviteMembers' => false
      }
    }
  end

  def expected_work_item_type_response(type = nil)
    base_scope = WorkItems::Type.default
    base_scope = base_scope.id_in(type.id) if type

    base_scope.map do |type|
      hash_including(
        'id' => type.to_global_id.to_s,
        'name' => type.name,
        'iconName' => type.icon_name,
        'widgetDefinitions' => match_array(widgets_for(type))
      )
    end
  end

  def widgets_for(type)
    type.widgets.map do |widget|
      base_attributes = { 'type' => widget.type.to_s.upcase }
      next base_attributes unless widget_attributes[widget.type]

      base_attributes.merge(widget_attributes[widget.type])
    end
  end
end

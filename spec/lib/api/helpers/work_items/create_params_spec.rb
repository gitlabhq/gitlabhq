# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::WorkItems::CreateParams, feature_category: :team_planning do
  describe ':work_item_create_features declared feature keys' do
    let(:declared_feature_keys) do
      %i[description assignees labels milestone hierarchy start_and_due_date linked_items]
    end

    it 'all map to widgets present in WidgetDefinition.available_widgets' do
      known_widget_symbols = ::WorkItems::TypesFramework::SystemDefined::WidgetDefinition
        .available_widgets.map(&:api_symbol)

      declared_feature_keys.each do |key|
        expect(known_widget_symbols).to include(:"#{key}_widget"),
          "Expected #{key}_widget to be a known widget symbol"
      end
    end
  end
end

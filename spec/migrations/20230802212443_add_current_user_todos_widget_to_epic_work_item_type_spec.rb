# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddCurrentUserTodosWidgetToEpicWorkItemType, :migration, feature_category: :team_planning do
  it_behaves_like 'migration that adds a widget to a work item type' do
    let(:target_type_enum_value) { described_class::EPIC_ENUM_VALUE }
    let(:target_type) { :epic }
    let(:widgets_for_type) do
      {
        'Assignees' => 0,
        'Description' => 1,
        'Hierarchy' => 2,
        'Labels' => 3,
        'Notes' => 5,
        'Start and due date' => 6,
        'Health status' => 7,
        'Status' => 11,
        'Notifications' => 14,
        'Award emoji' => 16
      }.freeze
    end
  end
end

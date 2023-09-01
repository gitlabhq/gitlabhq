# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddLinkedItemsWidgetToTicketWorkItemType, :migration, feature_category: :portfolio_management do
  it_behaves_like 'migration that adds a widget to a work item type' do
    let(:target_type_enum_value) { described_class::TICKET_ENUM_VALUE }
    let(:target_type) { :ticket }
    let(:additional_types) { { ticket: 8 } }
    let(:widgets_for_type) do
      {
        'Assignees' => 0,
        'Description' => 1,
        'Hierarchy' => 2,
        'Labels' => 3,
        'Notes' => 5,
        'Iteration' => 9,
        'Milestone' => 4,
        'Weight' => 8,
        'Current user todos' => 15,
        'Start and due date' => 6,
        'Health status' => 7,
        'Notifications' => 14,
        'Award emoji' => 16
      }.freeze
    end
  end
end

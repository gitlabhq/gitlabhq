# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RenameCustomStatusWidgetToStatusWidget, feature_category: :team_planning do
  let(:work_item_widget_definitions) { table(:work_item_widget_definitions) }
  let(:status_widget_type) { 26 }

  describe '#up' do
    it 'renames the custom status widget to status widget' do
      migrate!

      widget = work_item_widget_definitions.where(widget_type: status_widget_type).first
      expect(widget.name).to eq('Status')
    end
  end

  describe '#down' do
    it 'renames the status widget back to custom status widget' do
      schema_migrate_down!

      widget = work_item_widget_definitions.where(widget_type: status_widget_type).first
      expect(widget.name).to eq('Custom status')
    end
  end
end

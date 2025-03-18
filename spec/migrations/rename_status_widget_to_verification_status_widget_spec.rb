# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RenameStatusWidgetToVerificationStatusWidget, feature_category: :requirements_management do
  let(:work_item_widget_definitions) { table(:work_item_widget_definitions) }
  let(:status_widget_type) { 11 }

  describe '#up' do
    it 'renames the status widget to verification status widget' do
      migrate!

      widget = work_item_widget_definitions.where(widget_type: status_widget_type).first
      expect(widget.name).to eq('Verification status')
    end
  end

  describe '#down' do
    it 'renames the verification status widget back to status widget' do
      schema_migrate_down!

      widget = work_item_widget_definitions.where(widget_type: status_widget_type).first
      expect(widget.name).to eq('Status')
    end
  end
end

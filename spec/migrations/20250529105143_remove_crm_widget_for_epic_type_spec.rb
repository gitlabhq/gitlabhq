# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveCrmWidgetForEpicType, feature_category: :team_planning do
  let(:widget_id) { described_class::CRM_WIDGET_ID }
  let(:work_item_type_id) { described_class::EPIC_ID }

  let(:work_item_definitions) { table(:work_item_widget_definitions) }

  describe '#up', :migration_with_transaction do
    before do
      work_item_definitions.create!(name: "epic_crm_widget", widget_type: widget_id,
        work_item_type_id: work_item_type_id)
    end

    it "removes definitions for widget" do
      expect { migrate! }.to change { work_item_definitions.count }.by(-1)
    end
  end
end

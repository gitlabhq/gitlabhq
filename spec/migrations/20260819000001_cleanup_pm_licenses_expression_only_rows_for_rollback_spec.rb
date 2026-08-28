# frozen_string_literal: true

require "spec_helper"
require_migration!

RSpec.describe CleanupPmLicensesExpressionOnlyRowsForRollback, feature_category: :software_composition_analysis do
  let(:pm_licenses) { table(:pm_licenses) }

  let!(:identifier_row) do
    pm_licenses.create!(spdx_identifier: "MIT", created_at: Time.current, updated_at: Time.current)
  end

  let!(:expression_row) do
    pm_licenses.create!(spdx_expression: "MIT OR Apache-2.0", created_at: Time.current, updated_at: Time.current)
  end

  describe "#down" do
    it "removes expression-only rows and preserves identifier rows" do
      migrate!
      schema_migrate_down!

      expect(pm_licenses.where(spdx_identifier: nil)).to be_empty
      expect(pm_licenses.where(spdx_identifier: "MIT")).not_to be_empty
    end
  end
end

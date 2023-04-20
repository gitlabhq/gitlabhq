# frozen_string_literal: true

require "spec_helper"

require_migration!

RSpec.describe AddSbomComponentVersionForeignKeyToSbomVulnerableComponentVersions,
  feature_category: :dependency_management do
  let(:table) { described_class::SOURCE_TABLE }
  let(:column) { described_class::COLUMN }
  let(:foreign_key) { -> { described_class.new.foreign_keys_for(table, column).first } }

  it "creates and drops the foreign key" do
    reversible_migration do |migration|
      migration.before -> do
        expect(foreign_key.call).to be(nil)
      end

      migration.after -> do
        expect(foreign_key.call).to have_attributes(column: column.to_s)
      end
    end
  end
end

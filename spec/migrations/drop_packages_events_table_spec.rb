# frozen_string_literal: true

require "spec_helper"

require_migration!

RSpec.describe DropPackagesEventsTable, feature_category: :package_registry do
  let(:table) { described_class::SOURCE_TABLE }
  let(:column) { described_class::COLUMN }

  subject { described_class.new }

  it 'drops and creates the packages_events table' do
    reversible_migration do |migration|
      migration.before -> do
        expect(subject.table_exists?(:packages_events)).to eq(true)
      end

      migration.after -> do
        expect(subject.table_exists?(:packages_events)).to eq(false)
      end
    end
  end
end

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_column_with_default_to_large_table'

describe RuboCop::Cop::Migration::AddColumnWithDefaultToLargeTable do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    described_class::LARGE_TABLES.each do |table|
      it "registers an offense for the #{table} table" do
        inspect_source(cop, "add_column_with_default :#{table}, :column, default: true")

        aggregate_failures do
          expect(cop.offenses.size).to eq(1)
          expect(cop.offenses.map(&:line)).to eq([1])
        end
      end
    end

    it 'registers no offense for non-blacklisted tables' do
      inspect_source(cop, "add_column_with_default :table, :column, default: true")

      expect(cop.offenses).to be_empty
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      table = described_class::LARGE_TABLES.sample
      inspect_source(cop, "add_column_with_default :#{table}, :column, default: true")

      expect(cop.offenses).to be_empty
    end
  end
end

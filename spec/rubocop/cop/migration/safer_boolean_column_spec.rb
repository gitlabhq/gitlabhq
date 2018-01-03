require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/safer_boolean_column'

describe RuboCop::Cop::Migration::SaferBooleanColumn do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    described_class::SMALL_TABLES.each do |table|
      context "for the #{table} table" do
        sources_and_offense = [
          ["add_column :#{table}, :column, :boolean, default: true", 'should disallow nulls'],
          ["add_column :#{table}, :column, :boolean, default: false", 'should disallow nulls'],
          ["add_column :#{table}, :column, :boolean, default: nil", 'should have a default and should disallow nulls'],
          ["add_column :#{table}, :column, :boolean, null: false", 'should have a default'],
          ["add_column :#{table}, :column, :boolean, null: true", 'should have a default and should disallow nulls'],
          ["add_column :#{table}, :column, :boolean", 'should have a default and should disallow nulls'],
          ["add_column :#{table}, :column, :boolean, default: nil, null: false", 'should have a default'],
          ["add_column :#{table}, :column, :boolean, default: nil, null: true", 'should have a default and should disallow nulls'],
          ["add_column :#{table}, :column, :boolean, default: false, null: true", 'should disallow nulls']
        ]

        sources_and_offense.each do |source, offense|
          context "given the source \"#{source}\"" do
            it "registers the offense matching \"#{offense}\"" do
              inspect_source(source)

              aggregate_failures do
                expect(cop.offenses.first.message).to match(offense)
              end
            end
          end
        end

        inoffensive_sources = [
          "add_column :#{table}, :column, :boolean, default: true, null: false",
          "add_column :#{table}, :column, :boolean, default: false, null: false"
        ]

        inoffensive_sources.each do |source|
          context "given the source \"#{source}\"" do
            it "registers no offense" do
              inspect_source(source)

              aggregate_failures do
                expect(cop.offenses).to be_empty
              end
            end
          end
        end
      end
    end

    it 'registers no offense for tables not listed in SMALL_TABLES' do
      inspect_source("add_column :large_table, :column, :boolean")

      expect(cop.offenses).to be_empty
    end

    it 'registers no offense for non-boolean columns' do
      table = described_class::SMALL_TABLES.sample
      inspect_source("add_column :#{table}, :column, :string")

      expect(cop.offenses).to be_empty
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      table = described_class::SMALL_TABLES.sample
      inspect_source("add_column :#{table}, :column, :boolean")

      expect(cop.offenses).to be_empty
    end
  end
end

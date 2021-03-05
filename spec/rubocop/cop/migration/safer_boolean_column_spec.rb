# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/safer_boolean_column'

RSpec.describe RuboCop::Cop::Migration::SaferBooleanColumn do
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
              expect_offense(<<~RUBY, node: source, msg: offense)
                %{node}
                ^{node} Boolean columns on the `#{table}` table %{msg}.[...]
              RUBY
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
              expect_no_offenses(source)
            end
          end
        end
      end
    end

    it 'registers no offense for tables not listed in SMALL_TABLES' do
      expect_no_offenses("add_column :large_table, :column, :boolean")
    end

    it 'registers no offense for non-boolean columns' do
      table = described_class::SMALL_TABLES.sample
      expect_no_offenses("add_column :#{table}, :column, :string")
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      table = described_class::SMALL_TABLES.sample
      expect_no_offenses("add_column :#{table}, :column, :boolean")
    end
  end
end

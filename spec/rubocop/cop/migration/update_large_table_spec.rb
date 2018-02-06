require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/update_large_table'

describe RuboCop::Cop::Migration::UpdateLargeTable do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    shared_examples 'large tables' do |update_method|
      described_class::LARGE_TABLES.each do |table|
        it "registers an offense for the #{table} table" do
          inspect_source("#{update_method} :#{table}, :column, default: true")

          aggregate_failures do
            expect(cop.offenses.size).to eq(1)
            expect(cop.offenses.map(&:line)).to eq([1])
          end
        end
      end
    end

    context 'for the add_column_with_default method' do
      include_examples 'large tables', 'add_column_with_default'
    end

    context 'for the update_column_in_batches method' do
      include_examples 'large tables', 'update_column_in_batches'
    end

    it 'registers no offense for non-blacklisted tables' do
      inspect_source("add_column_with_default :table, :column, default: true")

      expect(cop.offenses).to be_empty
    end

    it 'registers no offense for non-blacklisted methods' do
      table = described_class::LARGE_TABLES.sample

      inspect_source("some_other_method :#{table}, :column, default: true")

      expect(cop.offenses).to be_empty
    end
  end

  context 'outside of migration' do
    let(:table) { described_class::LARGE_TABLES.sample }

    it 'registers no offense for add_column_with_default' do
      inspect_source("add_column_with_default :#{table}, :column, default: true")

      expect(cop.offenses).to be_empty
    end

    it 'registers no offense for update_column_in_batches' do
      inspect_source("add_column_with_default :#{table}, :column, default: true")

      expect(cop.offenses).to be_empty
    end
  end
end

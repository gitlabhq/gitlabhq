require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/reversible_add_column_with_default'

describe RuboCop::Cop::Migration::ReversibleAddColumnWithDefault do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when add_column_with_default is used inside a change method' do
      inspect_source('def change; add_column_with_default :table, :column, default: false; end')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end

    it 'registers no offense when add_column_with_default is used inside an up method' do
      inspect_source('def up; add_column_with_default :table, :column, default: false; end')

      expect(cop.offenses.size).to eq(0)
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      inspect_source('def change; add_column_with_default :table, :column, default: false; end')

      expect(cop.offenses.size).to eq(0)
    end
  end
end

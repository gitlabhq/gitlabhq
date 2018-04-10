require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/hash_index'

describe RuboCop::Cop::Migration::HashIndex do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when creating a hash index' do
      inspect_source('def change; add_index :table, :column, using: :hash; end')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end

    it 'registers an offense when creating a concurrent hash index' do
      inspect_source('def change; add_concurrent_index :table, :column, using: :hash; end')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end

    it 'registers an offense when creating a hash index using t.index' do
      inspect_source('def change; t.index :table, :column, using: :hash; end')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
      end
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      inspect_source('def change; index :table, :column, using: :hash; end')

      expect(cop.offenses.size).to eq(0)
    end
  end
end

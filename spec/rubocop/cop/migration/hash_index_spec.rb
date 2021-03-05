# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/hash_index'

RSpec.describe RuboCop::Cop::Migration::HashIndex do
  subject(:cop) { described_class.new }

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when creating a hash index' do
      expect_offense(<<~RUBY)
        def change
          add_index :table, :column, using: :hash
                                     ^^^^^^^^^^^^ hash indexes should be avoided at all costs[...]
        end
      RUBY
    end

    it 'registers an offense when creating a concurrent hash index' do
      expect_offense(<<~RUBY)
        def change
          add_concurrent_index :table, :column, using: :hash
                                                ^^^^^^^^^^^^ hash indexes should be avoided at all costs[...]
        end
      RUBY
    end

    it 'registers an offense when creating a hash index using t.index' do
      expect_offense(<<~RUBY)
        def change
          t.index :table, :column, using: :hash
                                   ^^^^^^^^^^^^ hash indexes should be avoided at all costs[...]
        end
      RUBY
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses('def change; index :table, :column, using: :hash; end')
    end
  end
end

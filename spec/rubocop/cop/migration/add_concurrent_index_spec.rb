# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/add_concurrent_index'

RSpec.describe RuboCop::Cop::Migration::AddConcurrentIndex do
  subject(:cop) { described_class.new }

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when add_concurrent_index is used inside a change method' do
      expect_offense(<<~RUBY)
        def change
            ^^^^^^ `add_concurrent_index` is not reversible[...]
          add_concurrent_index :table, :column
        end
      RUBY
    end

    it 'registers no offense when add_concurrent_index is used inside an up method' do
      expect_no_offenses('def up; add_concurrent_index :table, :column; end')
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses('def change; add_concurrent_index :table, :column; end')
    end
  end
end

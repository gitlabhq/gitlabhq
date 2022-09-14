# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/remove_index'

RSpec.describe RuboCop::Cop::Migration::RemoveIndex do
  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when remove_index is used' do
      expect_offense(<<~RUBY)
        def change
          remove_index :table, :column
          ^^^^^^^^^^^^ `remove_index` requires downtime, use `remove_concurrent_index` instead
        end
      RUBY
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses('def change; remove_index :table, :column; end')
    end
  end
end

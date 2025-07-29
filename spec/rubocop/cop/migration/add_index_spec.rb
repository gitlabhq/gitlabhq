# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/add_index'

RSpec.describe RuboCop::Cop::Migration::AddIndex do
  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when add_index is used' do
      expect_offense(<<~RUBY)
        def change
          add_index :table, :column
          ^^^^^^^^^ `add_index` requires downtime, use `add_concurrent_index` instead
        end
      RUBY
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        def change
          add_index :table, :column
        end
      RUBY
    end
  end
end

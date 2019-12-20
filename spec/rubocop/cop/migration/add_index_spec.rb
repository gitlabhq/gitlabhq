# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_index'

describe RuboCop::Cop::Migration::AddIndex do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when add_index is used' do
      expect_offense(<<~PATTERN.strip_indent)
        def change
          add_index :table, :column
          ^^^^^^^^^ `add_index` requires downtime, use `add_concurrent_index` instead
        end
      PATTERN
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~PATTERN.strip_indent)
        def change
          add_index :table, :column
        end
      PATTERN
    end
  end
end

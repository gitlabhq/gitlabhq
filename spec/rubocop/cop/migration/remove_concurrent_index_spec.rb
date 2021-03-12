# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/remove_concurrent_index'

RSpec.describe RuboCop::Cop::Migration::RemoveConcurrentIndex do
  subject(:cop) { described_class.new }

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when remove_concurrent_index is used inside a change method' do
      expect_offense(<<~RUBY)
        def change
            ^^^^^^ `remove_concurrent_index` is not reversible [...]
          remove_concurrent_index :table, :column
        end
      RUBY
    end

    it 'registers no offense when remove_concurrent_index is used inside an up method' do
      expect_no_offenses('def up; remove_concurrent_index :table, :column; end')
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      expect_no_offenses('def change; remove_concurrent_index :table, :column; end')
    end
  end
end

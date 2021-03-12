# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/remove_column'

RSpec.describe RuboCop::Cop::Migration::RemoveColumn do
  subject(:cop) { described_class.new }

  def source(meth = 'change')
    "def #{meth}; remove_column :table, :column; end"
  end

  context 'when in a regular migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
      allow(cop).to receive(:in_post_deployment_migration?).and_return(false)
    end

    it 'registers an offense when remove_column is used in the change method' do
      expect_offense(<<~RUBY)
        def change
          remove_column :table, :column
          ^^^^^^^^^^^^^ `remove_column` must only be used in post-deployment migrations
        end
      RUBY
    end

    it 'registers an offense when remove_column is used in the up method' do
      expect_offense(<<~RUBY)
        def up
          remove_column :table, :column
          ^^^^^^^^^^^^^ `remove_column` must only be used in post-deployment migrations
        end
      RUBY
    end

    it 'registers no offense when remove_column is used in the down method' do
      expect_no_offenses(source('down'))
    end
  end

  context 'when in a post-deployment migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
      allow(cop).to receive(:in_post_deployment_migration?).and_return(true)
    end

    it 'registers no offense' do
      expect_no_offenses(source)
    end
  end

  context 'when outside of a migration' do
    it 'registers no offense' do
      expect_no_offenses(source)
    end
  end
end

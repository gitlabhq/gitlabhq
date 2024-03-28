# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/ensure_factory_for_table'

RSpec.describe RuboCop::Cop::Migration::EnsureFactoryForTable, feature_category: :database do
  it 'registers an offense when a table does not have a corresponding factory' do
    allow(Dir).to receive(:glob).and_return([])

    expect_offense(<<~RUBY)
      create_table :users do |t|
      ^^^^^^^^^^^^^^^^^^^ No factory found for the table `users`.
        t.string :name
        t.timestamps
      end
    RUBY
  end

  it 'does not register an offense when a table has a corresponding factory' do
    allow(Dir).to receive(:glob).and_return(['users.rb'])

    expect_no_offenses(<<~RUBY)
      create_table :users do |t|
        t.string :name
        t.timestamps
      end
    RUBY
  end
end

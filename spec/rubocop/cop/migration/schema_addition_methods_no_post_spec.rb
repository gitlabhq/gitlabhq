# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/schema_addition_methods_no_post'

RSpec.describe RuboCop::Cop::Migration::SchemaAdditionMethodsNoPost, feature_category: :database do
  before do
    allow(cop).to receive(:time_enforced?).and_return true
  end

  it "does not allow 'add_column' to be called" do
    expect_offense(<<~RUBY)
      def up
        add_column(:table, :column, :boolean)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
      end
    RUBY
  end

  it "does not allow 'create_table' to be called" do
    expect_offense(<<~RUBY)
      def up
        create_table
        ^^^^^^^^^^^^ #{described_class::MSG}
      end
    RUBY
  end

  context "when rolling back migration" do
    it "allows 'add_column' to be called" do
      expect_no_offenses(<<~RUBY)
        def down
          add_column(:table, :column, :boolean)
        end
      RUBY
    end

    it "allows 'create_table' to be called" do
      expect_no_offenses(<<~RUBY)
        def down
          create_table
        end
      RUBY
    end

    it "allows forbidden method to be called within nested statement" do
      expect_no_offenses(<<~RUBY)
        def down
          add_column(:table, :column, :boolean) unless column_exists?(:table, :column)
        end
      RUBY
    end
  end
end

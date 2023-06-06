# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/schema_addition_methods_no_post'

RSpec.describe RuboCop::Cop::Migration::SchemaAdditionMethodsNoPost, feature_category: :database do
  before do
    allow(cop).to receive(:time_enforced?).and_return true
  end

  it "does not allow 'add_column' to be called" do
    expect_offense(<<~CODE)
      def up
        add_column(:table, :column, :boolean)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
      end
    CODE
  end

  it "does not allow 'create_table' to be called" do
    expect_offense(<<~CODE)
      def up
        create_table
        ^^^^^^^^^^^^ #{described_class::MSG}
      end
    CODE
  end

  context "when rolling back migration" do
    it "allows 'add_column' to be called" do
      expect_no_offenses(<<~CODE)
        def down
          add_column(:table, :column, :boolean)
        end
      CODE
    end

    it "allows 'create_table' to be called" do
      expect_no_offenses(<<~CODE)
        def down
          create_table
        end
      CODE
    end

    it "allows forbidden method to be called within nested statement" do
      expect_no_offenses(<<~CODE)
        def down
          add_column(:table, :column, :boolean) unless column_exists?(:table, :column)
        end
      CODE
    end
  end
end

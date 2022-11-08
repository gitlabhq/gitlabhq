# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/schema_addition_methods_no_post'

RSpec.describe RuboCop::Cop::Migration::SchemaAdditionMethodsNoPost do
  before do
    allow(cop).to receive(:time_enforced?).and_return true
  end

  it "does not allow 'add_column' to be called" do
    expect_offense(<<~CODE)
      add_column
      ^^^^^^^^^^ #{described_class::MSG}
    CODE
  end

  it "does not allow 'create_table' to be called" do
    expect_offense(<<~CODE)
      create_table
      ^^^^^^^^^^^^ #{described_class::MSG}
    CODE
  end
end

# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/avoid_inheritance_column'

RSpec.describe RuboCop::Cop::Database::AvoidInheritanceColumn, feature_category: :shared do
  it 'flags when :inheritance_column is used' do
    src = <<~SRC
      self.inheritance_column = 'some_column'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use Single Table Inheritance https://docs.gitlab.com/ee/development/database/single_table_inheritance.html
    SRC

    expect_offense(src)
  end

  it 'does not flag when :inheritance_column is set to :_type_disabled' do
    src = <<~SRC
      self.inheritance_column = :_type_disabled
    SRC

    expect_no_offenses(src)
  end
end

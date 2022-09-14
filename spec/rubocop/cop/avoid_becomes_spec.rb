# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/avoid_becomes'

RSpec.describe RuboCop::Cop::AvoidBecomes do
  it 'flags the use of becomes with a constant parameter' do
    expect_offense(<<~CODE)
      foo.becomes(Project)
      ^^^^^^^^^^^^^^^^^^^^ Avoid the use of becomes(SomeConstant), [...]
    CODE
  end

  it 'flags the use of becomes with a namespaced constant parameter' do
    expect_offense(<<~CODE)
      foo.becomes(Namespace::Group)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of becomes(SomeConstant), [...]
    CODE
  end

  it 'flags the use of becomes with a dynamic parameter' do
    expect_offense(<<~CODE)
      model = Namespace
      project = Project.first
      project.becomes(model)
      ^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of becomes(SomeConstant), [...]
    CODE
  end
end

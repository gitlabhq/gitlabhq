# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/avoid_becomes'

RSpec.describe RuboCop::Cop::AvoidBecomes, feature_category: :database do
  it 'flags the use of becomes with a constant parameter' do
    expect_offense(<<~RUBY)
      foo.becomes(Project)
      ^^^^^^^^^^^^^^^^^^^^ Avoid the use of becomes(SomeConstant), [...]
    RUBY
  end

  it 'flags the use of becomes with a namespaced constant parameter' do
    expect_offense(<<~RUBY)
      foo.becomes(Namespace::Group)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of becomes(SomeConstant), [...]
    RUBY
  end

  it 'flags the use of becomes with a dynamic parameter' do
    expect_offense(<<~RUBY)
      model = Namespace
      project = Project.first
      project.becomes(model)
      ^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of becomes(SomeConstant), [...]
    RUBY
  end
end

# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/graphql/gid_expected_type'

RSpec.describe RuboCop::Cop::Graphql::GIDExpectedType do
  subject(:cop) { described_class.new }

  it 'adds an offense when there is no expected_type parameter' do
    expect_offense(<<~TYPE)
      GitlabSchema.object_from_id(received_id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add an expected_type parameter to #object_from_id calls if possible.
    TYPE
  end

  it 'does not add an offense for calls that have an expected_type parameter' do
    expect_no_offenses(<<~TYPE.strip)
      GitlabSchema.object_from_id("some_id", expected_type: SomeClass)
    TYPE
  end
end

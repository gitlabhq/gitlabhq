# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'

require_relative '../../../../rubocop/cop/graphql/gid_expected_type'

RSpec.describe RuboCop::Cop::Graphql::GIDExpectedType, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'adds an offense when there is no expected_type parameter' do
    inspect_source(<<~TYPE)
      GitlabSchema.object_from_id(received_id)
    TYPE

    expect(cop.offenses.size).to eq 1
  end

  it 'does not add an offense for calls that have an expected_type parameter' do
    expect_no_offenses(<<~TYPE.strip)
      GitlabSchema.object_from_id("some_id", expected_type: SomeClass)
    TYPE
  end
end

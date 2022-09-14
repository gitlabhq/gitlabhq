# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/graphql/id_type'

RSpec.describe RuboCop::Cop::Graphql::IDType do
  it 'adds an offense when GraphQL::Types::ID is used as a param to #argument' do
    expect_offense(<<~TYPE)
      argument :some_arg, GraphQL::Types::ID, some: other, params: do_not_matter
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use GraphQL::Types::ID, use a specific GlobalIDType instead
    TYPE
  end

  context 'whitelisted arguments' do
    RuboCop::Cop::Graphql::IDType::WHITELISTED_ARGUMENTS.each do |arg|
      it "does not add an offense for calls to #argument with #{arg} as argument name" do
        expect_no_offenses(<<~TYPE.strip)
          argument #{arg}, GraphQL::Types::ID, some: other, params: do_not_matter
        TYPE
      end
    end
  end

  it 'does not add an offense for calls to #argument without GraphQL::Types::ID' do
    expect_no_offenses(<<~TYPE.strip)
      argument :some_arg, ::Types::GlobalIDType[::Awardable], some: other, params: do_not_matter
    TYPE
  end
end

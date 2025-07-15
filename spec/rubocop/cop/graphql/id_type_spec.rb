# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/graphql/id_type'

RSpec.describe RuboCop::Cop::Graphql::IDType, feature_category: :api do
  it 'adds an offense when GraphQL::Types::ID is used as a param to #argument' do
    expect_offense(<<~RUBY)
      argument :some_arg, GraphQL::Types::ID, some: other, params: do_not_matter
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use GraphQL::Types::ID, use a specific GlobalIDType instead
    RUBY
  end

  context 'allowlisted arguments' do
    RuboCop::Cop::Graphql::IDType::ALLOWLISTED_ARGUMENTS.each do |arg|
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

  it 'adds an offense when GraphQL::Types::ID is used with an IID field' do
    expect_offense(<<~RUBY)
      field :iid, GraphQL::Types::ID, some: other, params: do_not_matter
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use GraphQL::Types::ID for IIDs, use GraphQL::Types::String instead
    RUBY
  end

  it 'adds an offense when GraphQL::Types::ID is used with an IID-like field' do
    expect_offense(<<~RUBY)
      field :issue_iid, GraphQL::Types::ID, some: other, params: do_not_matter
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use GraphQL::Types::ID for IIDs, use GraphQL::Types::String instead
    RUBY
  end

  it 'adds an offense when GraphQL::Types::ID is used with an IID argument' do
    expect_offense(<<~RUBY)
      argument :iid, GraphQL::Types::ID, some: other, params: do_not_matter
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use GraphQL::Types::ID for IIDs, use GraphQL::Types::String instead
    RUBY
  end

  it 'adds an offense when GraphQL::Types::ID is used with an IID-like argument' do
    expect_offense(<<~RUBY)
      argument :merge_request_iid, GraphQL::Types::ID, some: other, params: do_not_matter
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use GraphQL::Types::ID for IIDs, use GraphQL::Types::String instead
    RUBY
  end

  it 'does not add an offense when GraphQL::Types::String is used with an IID field' do
    expect_no_offenses(<<~RUBY)
      field :iid, GraphQL::Types::String, some: other, params: do_not_matter
    RUBY
  end

  it 'does not add an offense when GraphQL::Types::String is used with an IID-like field' do
    expect_no_offenses(<<~RUBY)
      field :issue_iid, GraphQL::Types::String, some: other, params: do_not_matter
    RUBY
  end

  it 'does not add an offense when GraphQL::Types::String is used with an IID argument' do
    expect_no_offenses(<<~RUBY)
      argument :iid, GraphQL::Types::String, some: other, params: do_not_matter
    RUBY
  end

  it 'does not add an offense when GraphQL::Types::String is used with an IID-like argument' do
    expect_no_offenses(<<~RUBY)
      argument :merge_request_iid, GraphQL::Types::String, some: other, params: do_not_matter
    RUBY
  end
end

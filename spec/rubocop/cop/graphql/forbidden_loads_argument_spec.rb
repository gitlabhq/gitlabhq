# frozen_string_literal: true

require "rubocop_spec_helper"

require_relative "../../../../rubocop/cop/graphql/forbidden_loads_argument"

RSpec.describe RuboCop::Cop::Graphql::ForbiddenLoadsArgument, feature_category: :api do
  let(:msg) do
    "Do not use `loads:` in GraphQL arguments. " \
      "It leaks information about resource existence. " \
      "Instead, accept the ID and load/authorize the object manually in the resolver. " \
      "See https://docs.gitlab.com/ee/development/graphql_guide/authorization.html"
  end

  it "adds an offense when using loads: in an argument" do
    expect_offense(<<~RUBY)
      class SomeMutation < BaseMutation
        argument :milestone_id,
        ^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          ::Types::GlobalIDType[::Milestone],
          required: false,
          loads: Types::MilestoneType,
          description: 'The milestone to assign.'
      end
    RUBY
  end

  it "adds an offense when loads: is the only option" do
    expect_offense(<<~RUBY)
      class SomeMutation < BaseMutation
        argument :user_id, ::Types::GlobalIDType[::User], loads: Types::UserType
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      end
    RUBY
  end

  it "adds an offense when loads: is in an input type" do
    expect_offense(<<~RUBY)
      class SomeInputType < BaseInputObject
        argument :work_item_id,
        ^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          ::Types::GlobalIDType[::WorkItem],
          required: true,
          loads: ::Types::WorkItemType,
          description: 'The work item.'
      end
    RUBY
  end

  it "does not add an offense when the argument does not use loads:" do
    expect_no_offenses(<<~RUBY)
      class SomeMutation < BaseMutation
        argument :milestone_id,
          ::Types::GlobalIDType[::Milestone],
          required: false,
          description: 'The milestone ID to assign.'
      end
    RUBY
  end

  it "does not add an offense for arguments with other options" do
    expect_no_offenses(<<~RUBY)
      class SomeType < BaseObject
        argument :name, GraphQL::Types::String, required: true, description: 'The name.'
      end
    RUBY
  end

  it "adds an offense when type is passed as a keyword argument" do
    expect_offense(<<~RUBY)
      class SomeMutation < BaseMutation
        argument :milestone_id, type: ::Types::GlobalIDType[::Milestone], loads: Types::MilestoneType
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      end
    RUBY
  end

  it "adds an offense when description is passed as a positional argument" do
    expect_offense(<<~RUBY)
      class SomeMutation < BaseMutation
        argument :milestone_id, ::Types::GlobalIDType[::Milestone], 'The milestone.', loads: Types::MilestoneType
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      end
    RUBY
  end

  it "does not add an offense for field definitions" do
    expect_no_offenses(<<~RUBY)
      class SomeType < BaseObject
        field :milestone, Types::MilestoneType, null: true, description: 'The milestone.'
      end
    RUBY
  end

  it "does not add an offense when accepting the ID and loading/authorizing manually" do
    expect_no_offenses(<<~RUBY)
      class SomeMutation < BaseMutation
        argument :milestone_id,
          ::Types::GlobalIDType[::Milestone],
          required: false,
          description: 'The milestone ID to assign.'

        def resolve(milestone_id:)
          milestone = authorized_find!(id: milestone_id)
          # ...
        end
      end
    RUBY
  end
end

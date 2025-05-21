# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/database/avoid_scope_to'

RSpec.describe RuboCop::Cop::Database::AvoidScopeTo, feature_category: :database do
  it 'registers an offense for scope_to in a class' do
    expect_offense(<<~RUBY)
      class SomeMigration < BatchedMigrationJob
        scope_to ->(relation) { relation.where(version: [nil, 0]) }
        ^^^^^^^^ Avoid using `scope_to` inside batched background migration class definitions https://docs.gitlab.com/development/database/batched_background_migrations/#use-of-scope_to
      end
    RUBY
  end

  it 'does not register an offense when scope_to is not used' do
    expect_no_offenses(<<~RUBY)
      class SomeMigration < BatchedMigrationJob
        feature_category :web_ide
      end
    RUBY
  end
end

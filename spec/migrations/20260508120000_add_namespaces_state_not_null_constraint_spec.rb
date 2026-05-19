# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddNamespacesStateNotNullConstraint, feature_category: :groups_and_projects do
  it 'adds a NOT NULL constraint to the state column' do
    migrate!

    expect(Gitlab::Database::PostgresConstraint.check_constraints.by_table_identifier('public.namespaces'))
      .to include(have_attributes(name: 'check_9d490f2140', definition: 'CHECK ((state IS NOT NULL)) NOT VALID'))
  end

  it 'removes the NOT NULL constraint when rolled back' do
    migrate!
    schema_migrate_down!

    expect(Gitlab::Database::PostgresConstraint.check_constraints.by_table_identifier('public.namespaces'))
      .not_to include(have_attributes(name: 'check_9d490f2140'))
  end
end

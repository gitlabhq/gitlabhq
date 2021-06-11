# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteInternalIdsWhereFeatureFlagsUsage do
  let(:namespaces)   { table(:namespaces) }
  let(:projects)     { table(:projects) }
  let(:internal_ids) { table(:internal_ids) }

  def setup
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    projects.create!(namespace_id: namespace.id)
  end

  it 'deletes feature flag rows from the internal_ids table' do
    project = setup
    internal_ids.create!(project_id: project.id, usage: 6, last_value: 1)

    disable_migrations_output { migrate! }

    expect(internal_ids.count).to eq(0)
  end

  it 'does not delete issue rows from the internal_ids table' do
    project = setup
    internal_ids.create!(project_id: project.id, usage: 0, last_value: 1)

    disable_migrations_output { migrate! }

    expect(internal_ids.count).to eq(1)
  end

  it 'does not delete merge request rows from the internal_ids table' do
    project = setup
    internal_ids.create!(project_id: project.id, usage: 1, last_value: 1)

    disable_migrations_output { migrate! }

    expect(internal_ids.count).to eq(1)
  end
end

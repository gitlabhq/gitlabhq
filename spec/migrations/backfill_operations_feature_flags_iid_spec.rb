# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillOperationsFeatureFlagsIid do
  let(:namespaces)   { table(:namespaces) }
  let(:projects)     { table(:projects) }
  let(:flags)        { table(:operations_feature_flags) }

  def setup
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    projects.create!(namespace_id: namespace.id)
  end

  it 'migrates successfully when there are no flags in the database' do
    setup

    disable_migrations_output { migrate! }

    expect(flags.count).to eq(0)
  end

  it 'migrates successfully with a row in the table in both FOSS and EE' do
    project = setup
    flags.create!(project_id: project.id, active: true, name: 'test_flag')

    disable_migrations_output { migrate! }

    expect(flags.count).to eq(1)
  end
end

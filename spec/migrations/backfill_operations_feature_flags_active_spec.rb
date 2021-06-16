# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillOperationsFeatureFlagsActive do
  let(:namespaces)   { table(:namespaces) }
  let(:projects)     { table(:projects) }
  let(:flags)        { table(:operations_feature_flags) }

  def setup
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    projects.create!(namespace_id: namespace.id)
  end

  it 'executes successfully when there are no flags in the table' do
    setup

    disable_migrations_output { migrate! }

    expect(flags.count).to eq(0)
  end

  it 'updates active to true' do
    project = setup
    flag = flags.create!(project_id: project.id, name: 'test_flag', active: false)

    disable_migrations_output { migrate! }

    expect(flag.reload.active).to eq(true)
  end

  it 'updates active to true for multiple flags' do
    project = setup
    flag_a = flags.create!(project_id: project.id, name: 'test_flag', active: false)
    flag_b = flags.create!(project_id: project.id, name: 'other_flag', active: false)

    disable_migrations_output { migrate! }

    expect(flag_a.reload.active).to eq(true)
    expect(flag_b.reload.active).to eq(true)
  end

  it 'leaves active true if it is already true' do
    project = setup
    flag = flags.create!(project_id: project.id, name: 'test_flag', active: true)

    disable_migrations_output { migrate! }

    expect(flag.reload.active).to eq(true)
  end
end

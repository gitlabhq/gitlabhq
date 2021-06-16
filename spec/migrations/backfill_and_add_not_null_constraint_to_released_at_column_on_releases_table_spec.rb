# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillAndAddNotNullConstraintToReleasedAtColumnOnReleasesTable do
  let(:releases)   { table(:releases) }
  let(:namespaces) { table(:namespaces) }
  let(:projects)   { table(:projects) }

  subject(:migration) { described_class.new }

  it 'fills released_at with the value of created_at' do
    created_at_a = Time.zone.parse('2019-02-10T08:00:00Z')
    created_at_b = Time.zone.parse('2019-03-10T18:00:00Z')
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)
    release_a = releases.create!(project_id: project.id, created_at: created_at_a)
    release_b = releases.create!(project_id: project.id, created_at: created_at_b)

    disable_migrations_output { migration.up }

    release_a.reload
    release_b.reload
    expect(release_a.released_at).to eq(created_at_a)
    expect(release_b.released_at).to eq(created_at_b)
  end
end

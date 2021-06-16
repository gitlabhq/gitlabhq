# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillReleasesTableUpdatedAtAndAddNotNullConstraintsToTimestamps do
  let(:releases)   { table(:releases) }
  let(:namespaces) { table(:namespaces) }
  let(:projects)   { table(:projects) }

  subject(:migration) { described_class.new }

  it 'fills null updated_at rows with the value of created_at' do
    created_at_a = Time.zone.parse('2014-03-11T04:30:00Z')
    created_at_b = Time.zone.parse('2019-09-10T12:00:00Z')
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)
    release_a = releases.create!(project_id: project.id,
                                 released_at: Time.zone.parse('2014-12-10T06:00:00Z'),
                                 created_at: created_at_a)
    release_b = releases.create!(project_id: project.id,
                                 released_at: Time.zone.parse('2019-09-11T06:00:00Z'),
                                 created_at: created_at_b)
    release_a.update!(updated_at: nil)
    release_b.update!(updated_at: nil)

    disable_migrations_output { migrate! }

    release_a.reload
    release_b.reload
    expect(release_a.updated_at).to eq(created_at_a)
    expect(release_b.updated_at).to eq(created_at_b)
  end

  it 'does not change updated_at columns with a value' do
    created_at_a = Time.zone.parse('2014-03-11T04:30:00Z')
    updated_at_a = Time.zone.parse('2015-01-16T10:00:00Z')
    created_at_b = Time.zone.parse('2019-09-10T12:00:00Z')
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)
    release_a = releases.create!(project_id: project.id,
                                 released_at: Time.zone.parse('2014-12-10T06:00:00Z'),
                                 created_at: created_at_a,
                                 updated_at: updated_at_a)
    release_b = releases.create!(project_id: project.id,
                                 released_at: Time.zone.parse('2019-09-11T06:00:00Z'),
                                 created_at: created_at_b)
    release_b.update!(updated_at: nil)

    disable_migrations_output { migrate! }

    release_a.reload
    release_b.reload
    expect(release_a.updated_at).to eq(updated_at_a)
    expect(release_b.updated_at).to eq(created_at_b)
  end
end

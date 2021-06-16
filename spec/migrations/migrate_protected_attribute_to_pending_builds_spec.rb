# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20210610102413_migrate_protected_attribute_to_pending_builds.rb')

RSpec.describe MigrateProtectedAttributeToPendingBuilds do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:queue) { table(:ci_pending_builds) }
  let(:builds) { table(:ci_builds) }

  before do
    namespaces.create!(id: 123, name: 'sample', path: 'sample')
    projects.create!(id: 123, name: 'sample', path: 'sample', namespace_id: 123)

    builds.create!(id: 1, project_id: 123, status: 'pending', protected: false, type: 'Ci::Build')
    builds.create!(id: 2, project_id: 123, status: 'pending', protected: true, type: 'Ci::Build')
    builds.create!(id: 3, project_id: 123, status: 'pending', protected: false, type: 'Ci::Build')
    builds.create!(id: 4, project_id: 123, status: 'pending', protected: true, type: 'Ci::Bridge')
    builds.create!(id: 5, project_id: 123, status: 'success', protected: true, type: 'Ci::Build')

    queue.create!(id: 1, project_id: 123, build_id: 1)
    queue.create!(id: 2, project_id: 123, build_id: 2)
    queue.create!(id: 3, project_id: 123, build_id: 3)
  end

  it 'updates entries that should be protected' do
    migrate!

    expect(queue.where(protected: true).count).to eq 1
    expect(queue.find_by(protected: true).id).to eq 2
  end
end

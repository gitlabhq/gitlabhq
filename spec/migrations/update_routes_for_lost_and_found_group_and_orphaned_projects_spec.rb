# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db', 'post_migrate', '20200602143020_update_routes_for_lost_and_found_group_and_orphaned_projects.rb')

describe UpdateRoutesForLostAndFoundGroupAndOrphanedProjects, :migration do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:members) { table(:members) }
  let(:projects) { table(:projects) }
  let(:routes) { table(:routes) }

  before do
    # Create a Ghost User and its namnespace, but skip the route
    ghost_user = users.create!(
      name: 'Ghost User',
      username: 'ghost',
      email: 'ghost@example.com',
      user_type: described_class::User::USER_TYPE_GHOST,
      projects_limit: 100,
      state: :active,
      bio: 'This is a "Ghost User"'
    )

    namespaces.create!(
      name: 'Ghost User',
      path: 'ghost',
      owner_id: ghost_user.id,
      visibility_level: 20
    )

    # Create the 'lost-and-found', owned by the Ghost user, but with no route
    lost_and_found_group = namespaces.create!(
      name: described_class::User::LOST_AND_FOUND_GROUP,
      path: described_class::User::LOST_AND_FOUND_GROUP,
      type: 'Group',
      description: 'Group to store orphaned projects',
      visibility_level: 0
    )

    members.create!(
      type: 'GroupMember',
      source_id: lost_and_found_group.id,
      user_id: ghost_user.id,
      source_type: 'Namespace',
      access_level: described_class::User::ACCESS_LEVEL_OWNER,
      notification_level: 3
    )

    # Add an orphaned project under 'lost-and-found' but with the wrong path in its route
    orphaned_project = projects.create!(
      name: 'orphaned_project',
      path: 'orphaned_project',
      visibility_level: 20,
      archived: false,
      namespace_id: lost_and_found_group.id
    )

    routes.create!(
      source_id: orphaned_project.id,
      source_type: 'Project',
      path: 'orphaned_project',
      name: 'orphaned_project',
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    )
  end

  it 'creates the route for the ghost user namespace' do
    expect(routes.where(path: 'ghost').count).to eq(0)

    disable_migrations_output { migrate! }

    expect(routes.where(path: 'ghost').count).to eq(1)
  end

  it 'creates the route for the lost-and-found group' do
    expect(routes.where(path: described_class::User::LOST_AND_FOUND_GROUP).count).to eq(0)

    disable_migrations_output { migrate! }

    expect(routes.where(path: described_class::User::LOST_AND_FOUND_GROUP).count).to eq(1)
  end

  it 'updates the route for the orphaned project' do
    orphaned_project_route = routes.find_by(path: 'orphaned_project')
    expect(orphaned_project_route.name).to eq('orphaned_project')

    disable_migrations_output { migrate! }

    updated_route = routes.find_by(id: orphaned_project_route.id)
    expect(updated_route.path).to eq("#{described_class::User::LOST_AND_FOUND_GROUP}/orphaned_project")
    expect(updated_route.name).to eq("#{described_class::User::LOST_AND_FOUND_GROUP} / orphaned_project")
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::FixUserProjectRouteNames, :migration, schema: 20190620112608 do
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:routes) { table(:routes) }
  let(:projects) { table(:projects) }

  let(:user) { users.create(name: "The user's full name", projects_limit: 10, username: 'not-null', email: '1') }

  let(:namespace) do
    namespaces.create(
      owner_id: user.id,
      name: "Should eventually be the user's name",
      path: user.username
    )
  end

  let(:project) do
    projects.create(namespace_id: namespace.id, name: 'Project Name')
  end

  it "updates the route for a project if it did not match the user's name" do
    route = routes.create(
      id: 1,
      path: "#{user.username}/#{project.path}",
      source_id: project.id,
      source_type: 'Project',
      name: 'Completely wrong'
    )

    described_class.new.perform(1, 5)

    expect(route.reload.name).to eq("The user's full name / Project Name")
  end

  it 'updates the route for a project if the name was nil' do
    route = routes.create(
      id: 1,
      path: "#{user.username}/#{project.path}",
      source_id: project.id,
      source_type: 'Project',
      name: nil
    )

    described_class.new.perform(1, 5)

    expect(route.reload.name).to eq("The user's full name / Project Name")
  end

  it 'does not update routes that were are out of the range' do
    route = routes.create(
      id: 6,
      path: "#{user.username}/#{project.path}",
      source_id: project.id,
      source_type: 'Project',
      name: 'Completely wrong'
    )

    expect { described_class.new.perform(1, 5) }
      .not_to change { route.reload.name }
  end

  it 'does not update routes for projects in groups owned by the user' do
    group = namespaces.create(
      owner_id: user.id,
      name: 'A group',
      path: 'a-path',
      type: ''
    )
    project = projects.create(namespace_id: group.id, name: 'Project Name')
    route = routes.create(
      id: 1,
      path: "#{group.path}/#{project.path}",
      source_id: project.id,
      source_type: 'Project',
      name: 'Completely wrong'
    )

    expect { described_class.new.perform(1, 5) }
      .not_to change { route.reload.name }
  end

  it 'does not update routes for namespaces' do
    route = routes.create(
      id: 1,
      path: namespace.path,
      source_id: namespace.id,
      source_type: 'Namespace',
      name: 'Completely wrong'
    )

    expect { described_class.new.perform(1, 5) }
      .not_to change { route.reload.name }
  end
end

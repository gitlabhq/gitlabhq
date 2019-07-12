# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::FixUserNamespaceNames, :migration, schema: 20190620112608 do
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:user) { users.create(name: "The user's full name", projects_limit: 10, username: 'not-null', email: '1') }

  context 'updating the namespace names' do
    it 'updates a user namespace within range' do
      user2 = users.create(name: "Other user's full name", projects_limit: 10, username: 'also-not-null', email: '2')
      user_namespace1 = namespaces.create(
        id: 2,
        owner_id: user.id,
        name: "Should be the user's name",
        path: user.username
      )
      user_namespace2 = namespaces.create(
        id: 3,
        owner_id: user2.id,
        name: "Should also be the user's name",
        path: user.username
      )

      described_class.new.perform(1, 5)

      expect(user_namespace1.reload.name).to eq("The user's full name")
      expect(user_namespace2.reload.name).to eq("Other user's full name")
    end

    it 'does not update namespaces out of range' do
      user_namespace = namespaces.create(
        id: 6,
        owner_id: user.id,
        name: "Should be the user's name",
        path: user.username
      )

      expect { described_class.new.perform(1, 5) }
        .not_to change { user_namespace.reload.name }
    end

    it 'does not update groups owned by the users' do
      user_group = namespaces.create(
        id: 2,
        owner_id: user.id,
        name: 'A group name',
        path: 'the-path',
        type: 'Group'
      )

      expect { described_class.new.perform(1, 5) }
        .not_to change { user_group.reload.name }
    end
  end

  context 'namespace route names' do
    let(:routes) { table(:routes) }
    let(:namespace) do
      namespaces.create(
        id: 2,
        owner_id: user.id,
        name: "Will be updated to the user's name",
        path: user.username
      )
    end

    it "updates the route name if it didn't match the namespace" do
      route = routes.create(path: namespace.path, name: 'Incorrect name', source_type: 'Namespace', source_id: namespace.id)

      described_class.new.perform(1, 5)

      expect(route.reload.name).to eq("The user's full name")
    end

    it 'updates the route name if it was nil match the namespace' do
      route = routes.create(path: namespace.path, name: nil, source_type: 'Namespace', source_id: namespace.id)

      described_class.new.perform(1, 5)

      expect(route.reload.name).to eq("The user's full name")
    end

    it "doesn't update group routes" do
      route = routes.create(path: 'group-path', name: 'Group name', source_type: 'Group', source_id: namespace.id)

      expect { described_class.new.perform(1, 5) }
        .not_to change { route.reload.name }
    end

    it "doesn't touch routes for namespaces out of range" do
      user_namespace = namespaces.create(
        id: 6,
        owner_id: user.id,
        name: "Should be the user's name",
        path: user.username
      )

      expect { described_class.new.perform(1, 5) }
        .not_to change { user_namespace.reload.name }
    end
  end
end

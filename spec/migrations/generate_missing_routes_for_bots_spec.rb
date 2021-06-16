# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe GenerateMissingRoutesForBots, :migration do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:routes) { table(:routes) }

  let(:visual_review_bot) do
    users.create!(email: 'visual-review-bot@gitlab.com', name: 'GitLab Visual Review Bot', username: 'visual-review-bot', user_type: 3, projects_limit: 5)
  end

  let(:migration_bot) do
    users.create!(email: 'migration-bot@gitlab.com', name: 'GitLab Migration Bot', username: 'migration-bot', user_type: 7, projects_limit: 5)
  end

  let!(:visual_review_bot_namespace) do
    namespaces.create!(owner_id: visual_review_bot.id, name: visual_review_bot.name, path: visual_review_bot.username)
  end

  let!(:migration_bot_namespace) do
    namespaces.create!(owner_id: migration_bot.id, name: migration_bot.name, path: migration_bot.username)
  end

  context 'for bot users without an existing route' do
    it 'creates new routes' do
      expect { migrate! }.to change { routes.count }.by(2)
    end

    it 'creates new routes with the same path and name as their namespace' do
      migrate!

      [visual_review_bot, migration_bot].each do |bot|
        namespace = namespaces.find_by(owner_id: bot.id)
        route = route_for(namespace: namespace)

        expect(route.path).to eq(namespace.path)
        expect(route.name).to eq(namespace.name)
      end
    end
  end

  it 'does not create routes for bot users with existing routes' do
    create_route!(namespace: visual_review_bot_namespace)
    create_route!(namespace: migration_bot_namespace)

    expect { migrate! }.not_to change { routes.count }
  end

  it 'does not create routes for human users without an existing route' do
    human_namespace = create_human_namespace!(name: 'GitLab Human', username: 'human')

    expect { migrate! }.not_to change { route_for(namespace: human_namespace) }
  end

  it 'does not create route for a bot user with a missing route, if a human user with the same path already exists' do
    human_namespace = create_human_namespace!(name: visual_review_bot.name, username: visual_review_bot.username)
    create_route!(namespace: human_namespace)

    expect { migrate! }.not_to change { route_for(namespace: visual_review_bot_namespace) }
  end

  private

  def create_human_namespace!(name:, username:)
    human = users.create!(email: 'human@gitlab.com', name: name, username: username, user_type: nil, projects_limit: 5)
    namespaces.create!(owner_id: human.id, name: human.name, path: human.username)
  end

  def create_route!(namespace:)
    routes.create!(path: namespace.path, name: namespace.name, source_id: namespace.id, source_type: 'Namespace')
  end

  def route_for(namespace:)
    routes.find_by(source_type: 'Namespace', source_id: namespace.id)
  end
end

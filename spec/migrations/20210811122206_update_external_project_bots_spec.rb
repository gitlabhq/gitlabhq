# frozen_string_literal: true

require 'spec_helper'
require_migration!('update_external_project_bots')

RSpec.describe UpdateExternalProjectBots, :migration do
  def create_user(**extra_options)
    defaults = { projects_limit: 0, email: "#{extra_options[:username]}@example.com" }

    table(:users).create!(defaults.merge(extra_options))
  end

  it 'sets bot users as external if were created by external users' do
    internal_user = create_user(username: 'foo')
    external_user = create_user(username: 'bar', external: true)

    internal_project_bot = create_user(username: 'foo2', user_type: 6, created_by_id: internal_user.id, external: false)
    external_project_bot = create_user(username: 'bar2', user_type: 6, created_by_id: external_user.id, external: false)

    migrate!

    expect(table(:users).find(internal_project_bot.id).external).to eq false
    expect(table(:users).find(external_project_bot.id).external).to eq true
  end
end

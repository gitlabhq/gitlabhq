# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateUserHighestRolesTable, schema: 20200311130802 do
  let(:members) { table(:members) }
  let(:users) { table(:users) }
  let(:user_highest_roles) { table(:user_highest_roles) }

  def create_user(id, params = {})
    user_params = {
      id: id,
      state: 'active',
      user_type: nil,
      bot_type: nil,
      ghost: nil,
      email: "user#{id}@example.com",
      projects_limit: 0
    }.merge(params)

    users.create(user_params)
  end

  def create_member(id, access_level, params = {})
    params = {
      user_id: id,
      access_level: access_level,
      source_id: 1,
      source_type: 'Group',
      notification_level: 0
    }.merge(params)

    members.create(params)
  end

  before do
    create_user(1)
    create_user(2, state: 'blocked')
    create_user(3, user_type: 2)
    create_user(4)
    create_user(5, bot_type: 1)
    create_user(6, ghost: true)
    create_user(7, ghost: false)
    create_user(8)

    create_member(1, 40)
    create_member(7, 30)
    create_member(8, 20, requested_at: Time.current)

    user_highest_roles.create(user_id: 1, highest_access_level: 50)
  end

  describe '#perform' do
    it 'creates user_highest_roles rows according to users', :aggregate_failures do
      expect { subject.perform(1, 8) }.to change(UserHighestRole, :count).from(1).to(4)

      created_or_updated_rows = [
        { 'user_id' => 1, 'highest_access_level' => 40 },
        { 'user_id' => 4, 'highest_access_level' => nil },
        { 'user_id' => 7, 'highest_access_level' => 30 },
        { 'user_id' => 8, 'highest_access_level' => nil }
      ]

      rows = user_highest_roles.order(:user_id).map do |row|
        row.attributes.slice('user_id', 'highest_access_level')
      end

      expect(rows).to match_array(created_or_updated_rows)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe OrphanedInvitedMembersCleanup, :migration, feature_category: :subgroups do
  describe '#up', :aggregate_failures do
    it 'removes accepted members with no associated user' do
      user = create_user!('testuser1')

      create_member(invite_token: nil, invite_accepted_at: 1.day.ago)
      record2 = create_member(invite_token: nil, invite_accepted_at: 1.day.ago, user_id: user.id)
      record3 = create_member(invite_token: 'foo2', invite_accepted_at: nil)
      record4 = create_member(invite_token: 'foo3', invite_accepted_at: 1.day.ago)

      migrate!

      expect(table(:members).all.pluck(:id)).to match_array([record2.id, record3.id, record4.id])
    end
  end

  private

  def create_user!(name)
    email = "#{name}@example.com"

    table(:users).create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0
    )
  end

  def create_member(**extra_attributes)
    defaults = {
      access_level: 10,
      source_id: 1,
      source_type: "Project",
      notification_level: 0,
      type: 'ProjectMember'
    }

    table(:members).create!(defaults.merge(extra_attributes))
  end
end

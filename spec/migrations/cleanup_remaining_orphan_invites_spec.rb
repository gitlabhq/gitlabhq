# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupRemainingOrphanInvites, :migration, feature_category: :subgroups do
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

  def create_user(**extra_attributes)
    defaults = { projects_limit: 0 }
    table(:users).create!(defaults.merge(extra_attributes))
  end

  describe '#up', :aggregate_failures do
    it 'removes invite tokens for accepted records' do
      record1 = create_member(invite_token: 'foo', user_id: nil)
      record2 = create_member(invite_token: 'foo2', user_id: create_user(username: 'foo', email: 'foo@example.com').id)
      record3 = create_member(invite_token: nil, user_id: create_user(username: 'bar', email: 'bar@example.com').id)

      migrate!

      expect(table(:members).find(record1.id).invite_token).to eq 'foo'
      expect(table(:members).find(record2.id).invite_token).to eq nil
      expect(table(:members).find(record3.id).invite_token).to eq nil
    end
  end
end

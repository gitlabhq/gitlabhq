# frozen_string_literal: true

require 'spec_helper'
require_migration!('cleanup_orphan_project_access_tokens')

RSpec.describe CleanupOrphanProjectAccessTokens, :migration do
  def create_user(**extra_options)
    defaults = { state: 'active', projects_limit: 0, email: "#{extra_options[:username]}@example.com" }

    table(:users).create!(defaults.merge(extra_options))
  end

  def create_membership(**extra_options)
    defaults = { access_level: 30, notification_level: 0, source_id: 1, source_type: 'Project' }

    table(:members).create!(defaults.merge(extra_options))
  end

  let!(:regular_user) { create_user(username: 'regular') }
  let!(:orphan_bot) { create_user(username: 'orphaned_bot', user_type: 6) }
  let!(:used_bot) do
    create_user(username: 'used_bot', user_type: 6).tap do |bot|
      create_membership(user_id: bot.id)
    end
  end

  it 'marks all bots without memberships as deactivated' do
    expect do
      migrate!
      regular_user.reload
      orphan_bot.reload
      used_bot.reload
    end.to change {
      [regular_user.state, orphan_bot.state, used_bot.state]
    }.from(%w[active active active]).to(%w[active deactivated active])
  end

  it 'schedules for deletion all bots without memberships' do
    job_class = 'DeleteUserWorker'.safe_constantize

    if job_class
      expect(job_class).to receive(:bulk_perform_async).with([[orphan_bot.id, orphan_bot.id, skip_authorization: true]])

      migrate!
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveOrphanGroupTokenUsers, :migration, :sidekiq_inline,
  feature_category: :system_access do
  subject(:migration) { described_class.new }

  let(:users) { table(:users) }
  let!(:orphan_bot) do
    create_bot(username: 'orphan_bot', email: 'orphan_bot@bot.com').tap do |bot|
      namespaces.create!(type: 'User', path: 'n1', name: 'n1', owner_id: bot.id)
    end
  end

  let!(:valid_used_bot) do
    create_bot(username: 'used_bot', email: 'used_bot@bot.com').tap do |bot|
      group = namespaces.create!(type: 'Group', path: 'used_bot_group', name: 'used_bot_group')
      members.create!(
        user_id: bot.id,
        source_id: group.id,
        member_namespace_id: group.id,
        source_type: 'Group',
        access_level: 10,
        notification_level: 0
      )
    end
  end

  let!(:different_bot) do
    create_bot(username: 'other_bot', email: 'other_bot@bot.com', user_type: 5)
  end

  let(:personal_access_tokens) { table(:personal_access_tokens) }
  let(:members) { table(:members) }
  let(:namespaces) { table(:namespaces) }

  it 'initiates orphan project bot removal', :aggregate_failures do
    expect(DeleteUserWorker)
      .to receive(:perform_async)
            .with(orphan_bot.id, orphan_bot.id, skip_authorization: true)
            .and_call_original

    migrate!

    expect(Users::GhostUserMigration.where(user: orphan_bot)).to be_exists
    expect(users.count).to eq 3
    expect(personal_access_tokens.count).to eq 2
    expect(personal_access_tokens.find_by(user_id: orphan_bot.id)).to eq nil
  end

  context "when DeleteUserWorker doesn't fit anymore" do
    it 'removes project bot tokens only', :aggregate_failures do
      allow(DeleteUserWorker).to receive(:respond_to?).and_call_original
      allow(DeleteUserWorker).to receive(:respond_to?).with(:perform_async).and_return(false)

      migrate!

      expect(users.count).to eq 3
      expect(personal_access_tokens.count).to eq 2
      expect(personal_access_tokens.find_by(user_id: orphan_bot.id)).to eq nil
    end
  end

  private

  def create_bot(**params)
    users.create!({ projects_limit: 0, state: 'active', user_type: 6 }.merge(params)).tap do |bot|
      personal_access_tokens.create!(user_id: bot.id, name: "BOT##{bot.id}")
    end
  end
end

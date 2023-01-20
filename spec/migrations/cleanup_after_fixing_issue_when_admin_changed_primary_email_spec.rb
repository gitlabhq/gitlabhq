# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupAfterFixingIssueWhenAdminChangedPrimaryEmail, :sidekiq, feature_category: :user_profile do
  let(:migration) { described_class.new }
  let(:users) { table(:users) }
  let(:emails) { table(:emails) }

  let!(:user_1) { users.create!(name: 'confirmed-user-1', email: 'confirmed-1@example.com', confirmed_at: 3.days.ago, projects_limit: 100) }
  let!(:user_2) { users.create!(name: 'confirmed-user-2', email: 'confirmed-2@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }
  let!(:user_3) { users.create!(name: 'confirmed-user-3', email: 'confirmed-3@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }
  let!(:user_4) { users.create!(name: 'unconfirmed-user', email: 'unconfirmed@example.com', confirmed_at: nil, projects_limit: 100) }

  let!(:email_1) { emails.create!(email: 'confirmed-1@example.com', user_id: user_1.id, confirmed_at: 1.day.ago) }
  let!(:email_2) { emails.create!(email: 'other_2@example.com', user_id: user_2.id, confirmed_at: 1.day.ago) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'adds the primary email to emails for leftover confirmed users that do not have their primary email in the emails table', :aggregate_failures do
    original_email_1_confirmed_at = email_1.reload.confirmed_at

    expect { migration.up }.to change { emails.count }.by(2)

    expect(emails.find_by(user_id: user_2.id, email: 'confirmed-2@example.com').confirmed_at).to eq(user_2.reload.confirmed_at)
    expect(emails.find_by(user_id: user_3.id, email: 'confirmed-3@example.com').confirmed_at).to eq(user_3.reload.confirmed_at)
    expect(email_1.reload.confirmed_at).to eq(original_email_1_confirmed_at)

    expect(emails.exists?(user_id: user_4.id)).to be(false)
  end

  it 'continues in case of errors with one email' do
    allow(Email).to receive(:create) { raise 'boom!' }

    expect { migration.up }.not_to raise_error
  end
end

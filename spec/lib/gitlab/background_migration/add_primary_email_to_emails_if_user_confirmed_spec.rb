# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::AddPrimaryEmailToEmailsIfUserConfirmed do
  let(:users) { table(:users) }
  let(:emails) { table(:emails) }

  let!(:unconfirmed_user) { users.create!(name: 'unconfirmed', email: 'unconfirmed@example.com', confirmed_at: nil, projects_limit: 100) }
  let!(:confirmed_user_1) { users.create!(name: 'confirmed-1', email: 'confirmed-1@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }
  let!(:confirmed_user_2) { users.create!(name: 'confirmed-2', email: 'confirmed-2@example.com', confirmed_at: 1.day.ago, projects_limit: 100) }
  let!(:email) { emails.create!(user_id: confirmed_user_1.id, email: 'confirmed-1@example.com', confirmed_at: 1.day.ago) }

  let(:perform) { described_class.new.perform(users.first.id, users.last.id) }

  it 'adds the primary email of confirmed users to Emails, unless already added', :aggregate_failures do
    expect(emails.where(email: [unconfirmed_user.email, confirmed_user_2.email])).to be_empty

    expect { perform }.not_to raise_error

    expect(emails.where(email: unconfirmed_user.email).count).to eq(0)
    expect(emails.where(email: confirmed_user_1.email, user_id: confirmed_user_1.id).count).to eq(1)
    expect(emails.where(email: confirmed_user_2.email, user_id: confirmed_user_2.id).count).to eq(1)

    email_2 = emails.find_by(email: confirmed_user_2.email, user_id: confirmed_user_2.id)
    expect(email_2.confirmed_at).to eq(confirmed_user_2.reload.confirmed_at)
  end

  it 'sets timestamps on the created Emails' do
    perform

    email_2 = emails.find_by(email: confirmed_user_2.email, user_id: confirmed_user_2.id)

    expect(email_2.created_at).not_to be_nil
    expect(email_2.updated_at).not_to be_nil
  end

  context 'when a range of IDs is specified' do
    let!(:confirmed_user_3) { users.create!(name: 'confirmed-3', email: 'confirmed-3@example.com', confirmed_at: 1.hour.ago, projects_limit: 100) }
    let!(:confirmed_user_4) { users.create!(name: 'confirmed-4', email: 'confirmed-4@example.com', confirmed_at: 1.hour.ago, projects_limit: 100) }

    it 'only acts on the specified range of IDs', :aggregate_failures do
      expect do
        described_class.new.perform(confirmed_user_2.id, confirmed_user_3.id)
      end.to change { Email.count }.by(2)
      expect(emails.where(email: confirmed_user_4.email).count).to eq(0)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateDetumbledEmailInEmails, feature_category: :user_management do
  let(:emails) { table(:emails) }
  let(:users) { table(:users) }
  let!(:user) { users.create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10) }

  let!(:email1) do
    emails.create!(user_id: user.id, email: 'user@gmail.com')
  end

  let!(:email2) do
    emails.create!(user_id: user.id, email: 'user.name+gitlab@gmail.com')
  end

  let!(:email3) do
    emails.create!(user_id: user.id, email: 'user.name@example.com', detumbled_email: 'already_set@example.com')
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        start_id: emails.first.id,
        end_id: emails.last.id,
        batch_table: :emails,
        batch_column: :id,
        sub_batch_size: emails.count,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    let(:expected_names) { %w[user@gmail.com username@gmail.com user.name@example.com] }

    it 'successfully sets the detumbled_email' do
      expect { perform_migration }.to change { email1.reload.detumbled_email }.from(nil).to('user@gmail.com')
        .and change { email2.reload.detumbled_email }.from(nil).to('username@gmail.com')
        .and not_change { email3.reload.detumbled_email }
    end
  end
end

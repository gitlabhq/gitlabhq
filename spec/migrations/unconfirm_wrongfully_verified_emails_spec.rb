# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UnconfirmWrongfullyVerifiedEmails do
  before do
    user = table(:users).create!(name: 'user1', email: 'test1@test.com', projects_limit: 1)
    table(:emails).create!(email: 'test2@test.com', user_id: user.id)
  end

  context 'when email confirmation is enabled' do
    before do
      table(:application_settings).create!(send_user_confirmation_email: true)
    end

    it 'enqueues WrongullyConfirmedEmailUnconfirmer job' do
      Sidekiq::Testing.fake! do
        migrate!

        jobs = BackgroundMigrationWorker.jobs
        expect(jobs.size).to eq(1)
        expect(jobs.first["args"].first).to eq(Gitlab::BackgroundMigration::WrongfullyConfirmedEmailUnconfirmer.name.demodulize)
      end
    end
  end

  context 'when email confirmation is disabled' do
    before do
      table(:application_settings).create!(send_user_confirmation_email: false)
    end

    it 'does not enqueue WrongullyConfirmedEmailUnconfirmer job' do
      Sidekiq::Testing.fake! do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(0)
      end
    end
  end

  context 'when email application setting record does not exist' do
    before do
      table(:application_settings).delete_all
    end

    it 'does not enqueue WrongullyConfirmedEmailUnconfirmer job' do
      Sidekiq::Testing.fake! do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(0)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200615111857_unconfirm_wrongfully_verified_emails.rb')

RSpec.describe UnconfirmWrongfullyVerifiedEmails do
  before do
    user = table(:users).create!(name: 'user1', email: 'test1@test.com', projects_limit: 1)
    table(:emails).create!(email: 'test2@test.com', user_id: user.id)
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

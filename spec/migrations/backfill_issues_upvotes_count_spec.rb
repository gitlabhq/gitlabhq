# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillIssuesUpvotesCount do
  let(:migration) { described_class.new }
  let(:issues) { table(:issues) }
  let(:award_emoji) { table(:award_emoji) }

  let!(:issue1) { issues.create! }
  let!(:issue2) { issues.create! }
  let!(:issue3) { issues.create! }
  let!(:issue4) { issues.create! }
  let!(:issue4_without_thumbsup) { issues.create! }

  let!(:award_emoji1) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue1.id) }
  let!(:award_emoji2) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue2.id) }
  let!(:award_emoji3) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue3.id) }
  let!(:award_emoji4) { award_emoji.create!( name: 'thumbsup', awardable_type: 'Issue', awardable_id: issue4.id) }

  it 'correctly schedules background migrations' do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_migration(issue1.id, issue2.id)
        expect(described_class::MIGRATION).to be_scheduled_migration(issue3.id, issue4.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end

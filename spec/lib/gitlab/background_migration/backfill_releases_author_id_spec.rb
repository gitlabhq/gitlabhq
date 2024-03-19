# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillReleasesAuthorId,
  :migration, schema: 20230616082958, feature_category: :release_orchestration do
  let(:releases_table) { table(:releases) }
  let(:user_table) { table(:users) }
  let(:date_time) { DateTime.now }

  let!(:test_user) { user_table.create!(name: 'test', email: 'test@example.com', username: 'test', projects_limit: 10) }
  let!(:ghost_user) do
    user_table.create!(
      name: 'ghost', email: 'ghost@example.com',
      username: 'ghost', user_type: User::USER_TYPES['ghost'], projects_limit: 100000
    )
  end

  let(:migration) do
    described_class.new(
      start_id: 1, end_id: 100,
      batch_table: :releases, batch_column: :id,
      sub_batch_size: 10, pause_ms: 0,
      job_arguments: [ghost_user.id],
      connection: ApplicationRecord.connection
    )
  end

  subject(:perform_migration) { migration.perform }

  before do
    releases_table.create!(
      tag: 'tag1', name: 'tag1', released_at: (date_time - 1.minute), author_id: test_user.id
    )

    releases_table.create!(
      tag: 'tag2', name: 'tag2', released_at: (date_time - 2.minutes), author_id: test_user.id
    )

    releases_table.new(
      tag: 'tag3', name: 'tag3', released_at: (date_time - 3.minutes), author_id: nil
    ).save!(validate: false)

    releases_table.new(
      tag: 'tag4', name: 'tag4', released_at: (date_time - 4.minutes), author_id: nil
    ).save!(validate: false)

    releases_table.new(
      tag: 'tag5', name: 'tag5', released_at: (date_time - 5.minutes), author_id: nil
    ).save!(validate: false)

    releases_table.create!(
      tag: 'tag6', name: 'tag6', released_at: (date_time - 6.minutes), author_id: test_user.id
    )

    releases_table.new(
      tag: 'tag7', name: 'tag7', released_at: (date_time - 7.minutes), author_id: nil
    ).save!(validate: false)
  end

  it 'backfills `author_id` for the selected records', :aggregate_failures do
    expect(releases_table.where(author_id: ghost_user.id).count).to eq 0
    expect(releases_table.where(author_id: nil).count).to eq 4

    perform_migration

    expect(releases_table.where(author_id: ghost_user.id).count).to eq 4
    expect(releases_table.where(author_id: ghost_user.id).pluck(:name)).to include('tag3', 'tag4', 'tag5', 'tag7')
    expect(releases_table.where(author_id: test_user.id).count).to eq 3
    expect(releases_table.where(author_id: test_user.id).pluck(:name)).to include('tag1', 'tag2', 'tag6')
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end

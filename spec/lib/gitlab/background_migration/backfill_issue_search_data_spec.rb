# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssueSearchData, :migration, schema: 20220326161803 do
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:issue_search_data_table) { table(:issue_search_data) }

  let!(:namespace) { namespaces_table.create!(name: 'gitlab-org', path: 'gitlab-org') }
  let!(:project) { projects_table.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: namespace.id) }
  let!(:issues) { Array.new(10) { table(:issues).create!(project_id: project.id, title: 'test title', description: 'test description') } }

  let(:migration) { described_class.new }

  before do
    allow(migration).to receive(:sleep)
  end

  it 'backfills search data for the specified records' do
    # sleeps for every sub-batch
    expect(migration).to receive(:sleep).with(0.05).exactly(3).times

    migration.perform(issues[0].id, issues[5].id, :issues, :id, 2, 50)

    expect(issue_search_data_table.count).to eq(6)
  end

  it 'skips issues that already have search data' do
    old_time = Time.new(2019, 1, 1).in_time_zone
    issue_search_data_table.create!(project_id: project.id, issue_id: issues[0].id, updated_at: old_time)

    migration.perform(issues[0].id, issues[5].id, :issues, :id, 2, 50)

    expect(issue_search_data_table.count).to eq(6)
    expect(issue_search_data_table.find_by_issue_id(issues[0].id).updated_at).to be_like_time(old_time)
  end

  it 'rescues batch with bad data and inserts other rows' do
    issues[1].update!(description: Array.new(30_000) { SecureRandom.hex }.join(' '))

    expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
      expect(logger).to receive(:error).with(a_hash_including(message: /string is too long for tsvector/, model_id: issues[1].id))
    end

    expect { migration.perform(issues[0].id, issues[5].id, :issues, :id, 2, 50) }.not_to raise_error

    expect(issue_search_data_table.count).to eq(5)
    expect(issue_search_data_table.find_by_issue_id(issues[1].id)).to eq(nil)
  end

  it 're-raises other errors' do
    allow(migration).to receive(:update_search_data).and_raise(ActiveRecord::StatementTimeout)

    expect { migration.perform(issues[0].id, issues[5].id, :issues, :id, 2, 50) }.to raise_error(ActiveRecord::StatementTimeout)
  end
end

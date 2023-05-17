# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe Gitlab::BackgroundMigration::BackfillImportedIssueSearchData,
  :migration,
  schema: 20220707075300 do
  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:issue_search_data_table) { table(:issue_search_data) }

  let!(:user) { table(:users).create!(email: 'author@example.com', username: 'author', projects_limit: 10) }
  let!(:project) do
    table(:projects)
    .create!(
      namespace_id: namespace.id,
      creator_id: user.id,
      name: 'projecty',
      path: 'path',
      project_namespace_id: namespace.id)
  end

  let!(:issue) do
    table(:issues).create!(
      project_id: project.id,
      namespace_id: project.project_namespace_id,
      title: 'Patterson',
      description: FFaker::HipsterIpsum.paragraph
    )
  end

  let(:migration) do
    described_class.new(
      start_id: issue.id,
      end_id: issue.id + 30,
      batch_table: :issues,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  let(:perform_migration) { migration.perform }

  context 'when issue has search data record' do
    let!(:issue_search_data) { issue_search_data_table.create!(project_id: project.id, issue_id: issue.id) }

    it 'does not create or update any search data records' do
      expect { perform_migration }
        .to not_change { issue_search_data_table.count }
        .and not_change { issue_search_data }

      expect(issue_search_data_table.count).to eq(1)
    end
  end

  context 'when issue has no search data record' do
    let(:title_node) { "'#{issue.title.downcase}':1A" }

    it 'creates search data records' do
      expect { perform_migration }
        .to change { issue_search_data_table.count }.from(0).to(1)

      expect(issue_search_data_table.find_by(project_id: project.id).issue_id)
        .to eq(issue.id)

      expect(issue_search_data_table.find_by(project_id: project.id).search_vector)
        .to include(title_node)
    end
  end

  context 'error handling' do
    let!(:issue2) do
      table(:issues).create!(
        project_id: project.id,
        namespace_id: project.project_namespace_id,
        title: 'Chatterton',
        description: FFaker::HipsterIpsum.paragraph
      )
    end

    before do
      issue.update!(description: Array.new(30_000) { SecureRandom.hex }.join(' '))
    end

    let(:title_node2) { "'#{issue2.title.downcase}':1A" }

    it 'skips insertion for that issue but continues with migration' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
        expect(logger)
        .to receive(:error)
        .with(a_hash_including(message: /string is too long for tsvector/, model_id: issue.id))
      end

      expect { perform_migration }.to change { issue_search_data_table.count }.from(0).to(1)
      expect(issue_search_data_table.find_by(issue_id: issue.id)).to eq(nil)
      expect(issue_search_data_table.find_by(issue_id: issue2.id).search_vector)
        .to include(title_node2)
    end

    it 're-raises exceptions' do
      allow(migration)
        .to receive(:update_search_data_individually)
        .and_raise(ActiveRecord::StatementTimeout)

      expect { perform_migration }.to raise_error(ActiveRecord::StatementTimeout)
    end
  end
end

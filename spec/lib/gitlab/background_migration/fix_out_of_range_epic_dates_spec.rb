# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixOutOfRangeEpicDates, feature_category: :team_planning do
  let!(:organization) do
    table(:organizations).create!(
      name: 'organization',
      path: 'organization'
    )
  end

  let!(:namespace) do
    table(:namespaces).create!(
      name: 'Namespace 1',
      path: 'namespace1',
      organization_id: organization.id
    )
  end

  let!(:author) do
    table(:users).create!(
      username: 'tester',
      projects_limit: 100,
      organization_id: organization.id
    )
  end

  let(:issue_work_item_type_id) { table(:work_item_types).find_by(name: 'Issue').id }
  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: namespace.id,
      work_item_type_id: issue_work_item_type_id
    )
  end

  let(:migration) do
    described_class.new(
      start_id: epics_table.minimum(:id),
      end_id: epics_table.maximum(:id),
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  let(:epics_table) { table(:epics) }

  def create_epic(**attrs)
    title = "Epic #{Time.current}"
    attrs.reverse_merge!(
      iid: epics_table.maximum(:id).to_i + 1,
      group_id: namespace.id,
      author_id: author.id,
      issue_id: issue.id,
      title: title,
      title_html: title
    )

    epics_table.create!(attrs)
  end

  describe '#perform' do
    %i[start_date start_date_fixed end_date due_date_fixed].each do |field|
      it 'migrates the invalid dates' do
        record = create_epic(field => ::WorkItems::DatesSource::MAX_DATE_LIMIT + 1.day)

        expect { migration.perform }
          .to change { record.reload[field] }.to(::WorkItems::DatesSource::MAX_DATE_LIMIT)
      end
    end
  end
end

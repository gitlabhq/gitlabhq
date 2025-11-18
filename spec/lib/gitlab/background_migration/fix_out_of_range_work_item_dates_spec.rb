# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixOutOfRangeWorkItemDates, feature_category: :team_planning do
  let(:work_item_table) { table(:issues) }
  let(:work_item_dates_sources_table) { table(:work_item_dates_sources) }

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
  let(:work_item) do
    work_item_table.create!(
      title: 'First issue',
      iid: 1,
      namespace_id: namespace.id,
      work_item_type_id: issue_work_item_type_id
    )
  end

  let(:migration) do
    described_class.new(
      start_id: work_item_dates_sources_table.minimum(:issue_id),
      end_id: work_item_dates_sources_table.maximum(:issue_id),
      batch_table: :work_item_dates_sources,
      batch_column: :issue_id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  def create_work_item(**attrs)
    title = "WorkItem #{Time.current}"
    attrs.reverse_merge!(
      work_item_type_id: issue_work_item_type_id,
      iid: work_item_dates_sources_table.maximum(:issue_id).to_i + 1,
      namespace_id: namespace.id,
      author_id: author.id,
      title: title,
      title_html: title
    )

    work_item_table.create!(attrs)
  end

  def create_work_item_dates(work_item, **attrs)
    attrs.reverse_merge!(
      issue_id: work_item.id,
      namespace_id: work_item.namespace_id
    )

    work_item_dates_sources_table.create!(attrs)
  end

  describe '#perform' do
    %i[start_date start_date_fixed due_date due_date_fixed].each do |field|
      it 'migrates the invalid dates' do
        work_item = create_work_item
        work_item_dates = create_work_item_dates(work_item, field => ::WorkItems::DatesSource::MAX_DATE_LIMIT + 1.day)

        expect { migration.perform }
          .to change { work_item_dates.reload[field] }.to(::WorkItems::DatesSource::MAX_DATE_LIMIT)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- this is intentional
RSpec.describe Gitlab::BackgroundMigration::BackfillIssueLinkIdOnRelatedEpicLinks, feature_category: :team_planning do
  let!(:epic_type_id) { table(:work_item_types).find_by(base_type: 7).id }
  let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    table(:namespaces).create!(name: 'my test group1', path: 'my-test-group1', organization_id: organization.id)
  end

  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:related_epic_links) { table(:related_epic_links) }
  let(:issue_links) { table(:issue_links) }
  let(:start_id) { related_epic_links.minimum(:id) }
  let(:end_id) { related_epic_links.maximum(:id) }

  # Source epics
  let(:source_epic_1) { create_epic_with_work_item(title: 'Epic 1', iid: 1) }
  let(:source_epic_2) { create_epic_with_work_item(title: 'Epic 2', iid: 2) }
  let(:source_epic_3) { create_epic_with_work_item(title: 'Epic 3', iid: 3) }
  let(:source_epic_4) { create_epic_with_work_item(title: 'Epic 4', iid: 4) }
  # Target epics
  let(:target_epic_1) { create_epic_with_work_item(title: 'Epic 5', iid: 5) }
  let(:target_epic_2) { create_epic_with_work_item(title: 'Epic 6', iid: 6) }
  let(:target_epic_3) { create_epic_with_work_item(title: 'Epic 7', iid: 7) }
  let(:target_epic_4) { create_epic_with_work_item(title: 'Epic 8', iid: 8) }

  # Epic links without a foreign key
  let!(:issue_link_1) { create_issue_link(source: source_epic_1, target: target_epic_1) }
  let!(:issue_link_2) { create_issue_link(source: source_epic_2, target: target_epic_2) }

  let!(:related_epic_link_1) { create_related_epic_link(source: source_epic_1, target: target_epic_1) }
  let!(:related_epic_link_2) { create_related_epic_link(source: source_epic_2, target: target_epic_2) }

  # # Epic link with a foreign key
  let!(:issue_link_3) { create_issue_link(source: source_epic_3, target: target_epic_3) }
  let!(:related_epic_link_3) do
    create_related_epic_link(source: source_epic_3, target: target_epic_3, issue_link: issue_link_3)
  end

  let!(:issue_link_4) { create_issue_link(source: source_epic_4, target: target_epic_4) }
  let!(:related_epic_link_4) do
    create_related_epic_link(source: source_epic_4, target: target_epic_4, issue_link: issue_link_4)
  end

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :related_epic_links,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  it 'backfills data correctly', :aggregate_failures do
    migration.perform

    expect(related_epic_link_1.reload.issue_link_id).to eq(issue_link_1.id)
    expect(related_epic_link_2.reload.issue_link_id).to eq(issue_link_2.id)
    expect(related_epic_link_3.reload.issue_link_id).to eq(issue_link_3.id)
    expect(related_epic_link_4.reload.issue_link_id).to eq(issue_link_4.id)
  end

  def create_epic_with_work_item(iid:, title:)
    wi = issues.create!(
      iid: iid,
      author_id: author.id,
      work_item_type_id: epic_type_id,
      namespace_id: namespace.id,
      lock_version: 1,
      title: title
    )

    epics.create!(
      iid: iid,
      title: title,
      title_html: title,
      group_id: namespace.id,
      author_id: author.id,
      issue_id: wi.id
    )
  end

  def create_related_epic_link(source:, target:, issue_link: nil)
    related_epic_links.create!(
      source_id: source.id,
      target_id: target.id,
      issue_link_id: issue_link&.id
    )
  end

  def create_issue_link(source:, target:)
    issue_links.create!(
      source_id: source.issue_id,
      target_id: target.issue_id
    )
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

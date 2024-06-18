# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRelatedEpicLinksToIssueLinks, feature_category: :team_planning do
  let!(:epic_type_id) { table(:work_item_types).find_by(base_type: 7).id }
  let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
  let!(:namespace) { table(:namespaces).create!(name: 'my test group1', path: 'my-test-group1') }

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

  # Epic links not in sync(without a corresponding issue links record)
  let!(:related_epic_link_1) { create_related_epic_link(source: source_epic_1, target: target_epic_1, link_type: 0) }
  let!(:related_epic_link_2) { create_related_epic_link(source: source_epic_2, target: target_epic_2, link_type: 1) }
  # Epic link in sync
  let!(:related_epic_link_3) { create_related_epic_link(source: source_epic_3, target: target_epic_3, link_type: 0) }
  let!(:synced_issue_link_1) do
    issue_links.create!(
      source_id: source_epic_3.issue_id,
      target_id: target_epic_3.issue_id,
      link_type: 0
    )
  end

  # Epic link in sync but with outdated value
  let!(:related_epic_link_4) { create_related_epic_link(source: source_epic_4, target: target_epic_4, link_type: 0) }
  let!(:synced_issue_link_2) do
    issue_links.create!(
      source_id: source_epic_4.issue_id,
      target_id: target_epic_4.issue_id,
      link_type: 1,
      created_at: 1.day.ago,
      updated_at: 1.hour.ago
    )
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

  RSpec::Matchers.define :have_synced_issue_link do
    match do |epic_link|
      source_work_item_id = epics.find(epic_link.source_id).issue_id
      target_work_item_id = epics.find(epic_link.target_id).issue_id

      issue_links.find_by(
        source_id: source_work_item_id,
        target_id: target_work_item_id,
        link_type: epic_link.link_type
      ).present?
    end
  end

  it 'backfills data correctly' do
    expect do
      migration.perform
    end.to change { issue_links.count }.from(2).to(4)
      .and not_change { synced_issue_link_1.reload }
      .and change { synced_issue_link_2.reload.link_type }.from(1).to(0)
      .and change { synced_issue_link_2.reload.created_at }.to(related_epic_link_4.reload.created_at)
      .and change { synced_issue_link_2.reload.updated_at }.to(related_epic_link_4.reload.updated_at)

    expect(related_epic_link_1).to have_synced_issue_link
    expect(related_epic_link_2).to have_synced_issue_link
    expect(related_epic_link_3).to have_synced_issue_link
    expect(related_epic_link_4).to have_synced_issue_link
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

  def create_related_epic_link(source:, target:, link_type:)
    related_epic_links.create!(
      source_id: source.id,
      target_id: target.id,
      link_type: link_type
    )
  end
end

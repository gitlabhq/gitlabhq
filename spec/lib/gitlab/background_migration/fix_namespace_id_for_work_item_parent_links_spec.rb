# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixNamespaceIdForWorkItemParentLinks, feature_category: :team_planning do
  let(:work_item_parent_links) { table(:work_item_parent_links) }
  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let!(:work_item_type_id) { table(:work_item_types).where(base_type: 1).first.id }
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }

  let!(:namespace1) { namespaces.create!(name: 'Namespace 1', path: 'namespace1', organization_id: organization.id) }
  let!(:namespace2) { namespaces.create!(name: 'Namespace 2', path: 'namespace2', organization_id: organization.id) }

  let!(:parent) { issues.create!(title: 'Parent', namespace_id: namespace1.id, work_item_type_id: work_item_type_id) }
  let!(:issue1) { issues.create!(title: 'Issue 1', namespace_id: namespace1.id, work_item_type_id: work_item_type_id) }
  let!(:issue2) { issues.create!(title: 'Issue 2', namespace_id: namespace2.id, work_item_type_id: work_item_type_id) }
  let!(:issue3) { issues.create!(title: 'Issue 3', namespace_id: namespace1.id, work_item_type_id: work_item_type_id) }

  let!(:correct_work_item_parent_link1) do
    work_item_parent_links.create!(work_item_id: issue1.id, work_item_parent_id: parent.id, namespace_id: namespace1.id)
  end

  let!(:correct_work_item_parent_link2) do
    work_item_parent_links.create!(work_item_id: issue2.id, work_item_parent_id: parent.id, namespace_id: namespace2.id)
  end

  let!(:inccorrect_work_item_parent_link) do
    work_item_parent_links.create!(work_item_id: issue3.id, work_item_parent_id: parent.id, namespace_id: namespace2.id)
  end

  let(:start_id) { work_item_parent_links.minimum(:id) }
  let(:end_id) { work_item_parent_links.maximum(:id) }

  describe '#perform' do
    it 'fixes the namespace_id for work item parent links' do
      expect(work_item_parent_links.where(namespace_id: namespace1.id).count).to eq(1)
      expect(work_item_parent_links.where(namespace_id: namespace2.id).count).to eq(2)

      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: :work_item_parent_links,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform

      expect(work_item_parent_links.where(namespace_id: namespace1.id).count).to eq(2)
      expect(work_item_parent_links.where(namespace_id: namespace2.id).count).to eq(1)

      expect(work_item_parent_links.where(work_item_id: issue1.id).first.namespace_id).to eq(namespace1.id)
      expect(work_item_parent_links.where(work_item_id: issue2.id).first.namespace_id).to eq(namespace2.id)
      expect(work_item_parent_links.where(work_item_id: issue3.id).first.namespace_id).to eq(namespace1.id)
    end
  end
end

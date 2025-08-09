# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillLabelsWithGroupProjectMissing, :migration_with_transaction, migration: :gitlab_main, feature_category: :team_planning do
  let(:labels) { table(:labels) }
  let(:organization) { table(:organizations).create!(id: 1, name: 'organization', path: 'organization') }
  let(:group) { table(:namespaces).create!(name: "group", path: "group", organization_id: organization.id) }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:parent_attributes) { [:group_id, :project_id] }
  let(:project) do
    table(:projects).create!(
      namespace_id: group.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:valid_project_label) { labels.create!(title: 'project label 1', type: 'ProjectLabel', project_id: project.id) }
  let!(:valid_group_label) { labels.create!(title: 'group label 1', type: 'GroupLabel', group_id: group.id) }

  let(:invalid_label1) { labels.create!(title: 'label1') }
  let(:invalid_label2) { labels.create!(title: 'label2') }
  let(:invalid_label3) { labels.create!(title: 'label3') }
  let(:invalid_label4) { labels.create!(title: 'label4') }
  let(:invalid_labels) { [invalid_label1, invalid_label2, invalid_label3, invalid_label4] }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      create_invalid_labels
    end

    it 'updates records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(/UPDATE\s+"labels"/, 2) # 2 batches
    end

    it 'backfills all invalid records' do
      expect do
        migrate!
        invalid_labels.each(&:reload)
      end.to change { invalid_labels.map { |l| [l.organization_id, l.group_id, l.project_id] } }.from(
        [
          [nil, nil, nil],
          [nil, nil, nil],
          [nil, nil, nil],
          [nil, nil, nil]
        ]
      ).to(
        [
          [1, nil, nil],
          [1, nil, nil],
          [1, nil, nil],
          [1, nil, nil]
        ]
      ).and(
        not_change { valid_project_label.reload.attributes.slice('organization_id', 'project_id', 'group_id').values }
          .from([nil, project.id, nil])
      ).and(
        not_change { valid_group_label.reload.attributes.slice('organization_id', 'project_id', 'group_id').values }
          .from([nil, nil, group.id])
      )
    end
  end

  def create_invalid_labels
    # Necessary as we can no longer create invalid test data due to the contraint, but we know it exists in production
    labels.connection.execute(<<~SQL)
      ALTER TABLE labels DROP CONSTRAINT check_2d9a8c1bca;
    SQL

    invalid_labels

    labels.connection.execute(<<~SQL)
      ALTER TABLE labels
        ADD CONSTRAINT check_2d9a8c1bca CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;
    SQL
  end
end

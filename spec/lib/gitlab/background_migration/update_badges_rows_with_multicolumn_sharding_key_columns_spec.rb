# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateBadgesRowsWithMulticolumnShardingKeyColumns, feature_category: :groups_and_projects do
  let(:connection) { ApplicationRecord.connection }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:group) do
    table(:namespaces).create!(name: 'name', path: 'path', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', organization_id: organization.id,
      project_namespace_id: group.id, namespace_id: group.id)
  end

  let(:badges) { table(:badges) }
  let(:migration_args) do
    {
      start_id: badges.minimum(:id),
      end_id: badges.maximum(:id),
      batch_table: :badges,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'sets group_id to NULL for rows where group_id IS NOT NULL and project_id IS NOT NULL' do
    drop_constraint

    badge1 = badges.create!(
      link_url: 'http://example.com',
      image_url: 'http://example.com',
      type: 'foo',
      group_id: group.id,
      project_id: project.id
    )
    badge1.reload
    expect(badge1.group_id).to eq(group.id)
    expect(badge1.project_id).to eq(project.id)

    recreate_constraint

    badge2 = badges.create!(
      link_url: 'http://example.com',
      image_url: 'http://example.com',
      type: 'foo',
      group_id: nil,
      project_id: project.id
    )
    badge2.reload
    expect(badge2.group_id).to be_nil
    expect(badge2.project_id).to eq(project.id)

    badge3 = badges.create!(
      link_url: 'http://example.com',
      image_url: 'http://example.com',
      type: 'foo',
      group_id: group.id,
      project_id: nil
    )
    badge3.reload
    expect(badge3.group_id).to eq(group.id)
    expect(badge3.project_id).to be_nil

    described_class.new(**migration_args).perform

    badge1.reload
    expect(badge1.group_id).to be_nil
    expect(badge1.project_id).to eq(project.id)

    badge2.reload
    expect(badge2.group_id).to be_nil
    expect(badge2.project_id).to eq(project.id)

    badge3.reload
    expect(badge3.group_id).to eq(group.id)
    expect(badge3.project_id).to be_nil
  end

  private

  def drop_constraint
    connection.execute(
      <<~SQL
        ALTER TABLE badges DROP CONSTRAINT IF EXISTS check_22ac1b6d3a;
      SQL
    )
  end

  def recreate_constraint
    connection.execute(
      <<~SQL
        ALTER TABLE badges
          ADD CONSTRAINT check_22ac1b6d3a CHECK ((num_nonnulls(group_id, project_id) = 1)) NOT VALID;
      SQL
    )
  end
end

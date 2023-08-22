# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUsersWithDefaults,
  schema: 20230818083610,
  feature_category: :user_profile do
  let(:users) { table(:users) }
  let(:columns) { [:project_view, :hide_no_ssh_key, :hide_no_password, :notified_of_own_activity] }
  let(:initial_column_values) do
    [
      [nil, nil, nil, nil],
      [0, nil, nil, nil],
      [nil, true, nil, nil],
      [nil, nil, true, nil],
      [nil, nil, nil, true]
    ]
      .map { |row| columns.zip(row).to_h }
  end

  let(:final_column_values) do
    [
      [2, false, false, false],
      [0, false, false, false],
      [2, true, false, false],
      [2, false, true, false],
      [2, false, false, true]
    ]
      .map { |row| columns.zip(row).to_h }
  end

  subject(:perform_migration) do
    described_class
      .new(
        start_id: users.minimum(:id),
        end_id: users.maximum(:id),
        batch_table: :users,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      )
      .perform
  end

  before do
    initial_column_values.each_with_index do |attributes, index|
      user = users.create!(**attributes.merge(projects_limit: 1, email: "user#{index}@gitlab.com"))
      final_column_values[index].merge!(id: user.id)
    end
  end

  it 'backfills the null values with the default values' do
    perform_migration

    final_column_values.each { |attributes| match_attributes(attributes) }
  end

  private

  def match_attributes(attributes)
    migrated_user = users.find(attributes[:id])
    expect(migrated_user.project_view).to eq(attributes[:project_view])
    expect(migrated_user.hide_no_ssh_key).to eq(attributes[:hide_no_ssh_key])
    expect(migrated_user.hide_no_password).to eq(attributes[:hide_no_password])
    expect(migrated_user.notified_of_own_activity).to eq(attributes[:notified_of_own_activity])
  end
end

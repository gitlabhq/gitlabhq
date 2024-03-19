# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUsersColorModeId,
  feature_category: :user_profile do
  let(:users) { table(:users) }
  let(:columns) { [:color_mode_id, :theme_id] }
  let(:initial_column_values) do
    [
      [1, 11],
      [2, 10],
      [1, 10]
    ]
      .map { |row| columns.zip(row).to_h }
  end

  let(:final_column_values) do
    [
      [2, 11],
      [2, 10],
      [1, 10]
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

  it 'backfills with the default values' do
    perform_migration

    final_column_values.each { |attributes| match_attributes(attributes) }
  end

  def match_attributes(attributes)
    migrated_user = users.find(attributes[:id])

    expect(migrated_user.color_mode_id).to eq(attributes[:color_mode_id])
    expect(migrated_user.theme_id).to eq(attributes[:theme_id])
  end
end

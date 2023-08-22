# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserPreferencesWithDefaults,
  schema: 20230818085219,
  feature_category: :user_profile do
  let(:user_preferences) { table(:user_preferences) }
  let(:users) { table(:users) }
  let(:columns) { [:tab_width, :time_display_relative, :render_whitespace_in_code] }
  let(:initial_column_values) do
    [
      [nil, nil, nil],
      [10, nil, nil],
      [nil, false, nil],
      [nil, nil, true]
    ]
      .map { |row| columns.zip(row).to_h }
  end

  let(:final_column_values) do
    [
      [8, true, false],
      [10, true, false],
      [8, false, false],
      [8, true, true]
    ]
      .map { |row| columns.zip(row).to_h }
  end

  subject(:perform_migration) do
    described_class
      .new(
        start_id: user_preferences.minimum(:id),
        end_id: user_preferences.maximum(:id),
        batch_table: :user_preferences,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      )
      .perform
  end

  before do
    initial_column_values.each_with_index do |attributes, index|
      user = users.create!(projects_limit: 1, email: "user#{index}@gitlab.com")
      user_preference = user_preferences.create!(attributes.merge(user_id: user.id))
      final_column_values[index].merge!(id: user_preference.id)
    end
  end

  it 'backfills the null values with the default values' do
    perform_migration

    final_column_values.each { |attributes| match_attributes(attributes) }
  end

  def match_attributes(attributes)
    migrated_user_preference = user_preferences.find(attributes[:id])

    expect(migrated_user_preference.tab_width).to eq(attributes[:tab_width])
    expect(migrated_user_preference.time_display_relative).to eq(attributes[:time_display_relative])
    expect(migrated_user_preference.render_whitespace_in_code).to eq(attributes[:render_whitespace_in_code])
  end
end

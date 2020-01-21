# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191128162854_drop_project_ci_cd_settings_merge_trains_enabled.rb')

describe DropProjectCiCdSettingsMergeTrainsEnabled, :migration do
  let!(:project_ci_cd_setting) { table(:project_ci_cd_settings) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(project_ci_cd_setting.column_names).to include("merge_trains_enabled")
      }

      migration.after -> {
        project_ci_cd_setting.reset_column_information
        expect(project_ci_cd_setting.column_names).not_to include("merge_trains_enabled")
      }
    end
  end
end

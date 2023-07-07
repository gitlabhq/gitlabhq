# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissingCiCdSettings, schema: 20230628023103, feature_category: :source_code_management do # rubocop:disable Layout/LineLength
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:ci_cd_settings_table) { table(:project_ci_cd_settings) }

  let(:namespace_1) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-1') }

  let(:project_namespace_2) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-2', type: 'Project') }
  let(:project_namespace_3) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-3', type: 'Project') }
  let(:project_namespace_4) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-4', type: 'Project') }
  let(:project_namespace_5) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-4', type: 'Project') }
  let!(:project_1) do
    projects_table
    .create!(
      name: 'project1',
      path: 'path1',
      namespace_id: namespace_1.id,
      project_namespace_id: project_namespace_2.id,
      visibility_level: 0
    )
  end

  let!(:project_2) do
    projects_table
    .create!(
      name: 'project2',
      path: 'path2',
      namespace_id: namespace_1.id,
      project_namespace_id: project_namespace_3.id,
      visibility_level: 0
    )
  end

  let!(:project_3) do
    projects_table
    .create!(
      name: 'project3',
      path: 'path3',
      namespace_id: namespace_1.id,
      project_namespace_id: project_namespace_4.id,
      visibility_level: 0
    )
  end

  let!(:ci_cd_settings_3) do
    ci_cd_settings_table.create!(project_id: project_3.id)
  end

  let!(:project_4) do
    projects_table
    .create!(
      name: 'project4',
      path: 'path4',
      namespace_id: namespace_1.id,
      project_namespace_id: project_namespace_5.id,
      visibility_level: 0
    )
  end

  subject(:perform_migration) do
    described_class.new(start_id: projects_table.minimum(:id),
      end_id: projects_table.maximum(:id),
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: projects_table.connection)
                   .perform
  end

  it 'creates ci_cd_settings for projects without ci_cd_settings' do
    expect { subject }.to change { ci_cd_settings_table.count }.from(1).to(4)
  end

  it 'creates ci_cd_settings with default values' do
    ci_cd_settings_table.where.not(project_id: ci_cd_settings_3.project_id).each do |ci_cd_setting|
      expect(ci_cd_setting.attributes.except('id', 'project_id')).to eq({
        "group_runners_enabled" => true,
        "merge_pipelines_enabled" => nil,
        "default_git_depth" => 20,
        "forward_deployment_enabled" => true,
        "merge_trains_enabled" => false,
        "auto_rollback_enabled" => false,
        "keep_latest_artifact" => false,
        "restrict_user_defined_variables" => false,
        "job_token_scope_enabled" => false,
        "runner_token_expiration_interval" => nil,
        "separated_caches" => true,
        "allow_fork_pipelines_to_run_in_parent_project" => true,
        "inbound_job_token_scope_enabled" => true
      })
    end
  end
end

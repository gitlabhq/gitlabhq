require 'migrations_helper'
require Rails.root.join('db', 'migrate', '20170525132202_migrate_pipeline_stages.rb')

describe MigratePipelineStages, :migration do
  ##
  # Create tables using schema from which we will migrate stuff.
  #
  before do
    ActiveRecord::Schema.define(version: 20170523091700) do
      enable_extension "plpgsql"
      enable_extension "pg_trgm"

      create_table "ci_pipelines", force: :cascade do |t|
        t.string "ref"
        t.string "sha"
        t.string "before_sha"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.boolean "tag", default: false
        t.text "yaml_errors"
        t.datetime "committed_at"
        t.integer "project_id"
        t.string "status"
        t.datetime "started_at"
        t.datetime "finished_at"
        t.integer "duration"
        t.integer "user_id"
        t.integer "lock_version"
        t.integer "auto_canceled_by_id"
        t.integer "pipeline_schedule_id"
      end

      add_index "ci_pipelines", ["auto_canceled_by_id"], name: "index_ci_pipelines_on_auto_canceled_by_id", using: :btree
      add_index "ci_pipelines", ["pipeline_schedule_id"], name: "index_ci_pipelines_on_pipeline_schedule_id", using: :btree
      add_index "ci_pipelines", ["project_id", "ref", "status"], name: "index_ci_pipelines_on_project_id_and_ref_and_status", using: :btree
      add_index "ci_pipelines", ["project_id", "sha"], name: "index_ci_pipelines_on_project_id_and_sha", using: :btree
      add_index "ci_pipelines", ["project_id"], name: "index_ci_pipelines_on_project_id", using: :btree
      add_index "ci_pipelines", ["status"], name: "index_ci_pipelines_on_status", using: :btree
      add_index "ci_pipelines", ["user_id"], name: "index_ci_pipelines_on_user_id", using: :btree

      create_table "ci_builds", force: :cascade do |t|
        t.string "status"
        t.datetime "finished_at"
        t.text "trace"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.datetime "started_at"
        t.integer "runner_id"
        t.float "coverage"
        t.integer "commit_id"
        t.text "commands"
        t.string "name"
        t.text "options"
        t.boolean "allow_failure", default: false, null: false
        t.string "stage"
        t.integer "trigger_request_id"
        t.integer "stage_idx"
        t.boolean "tag"
        t.string "ref"
        t.integer "user_id"
        t.string "type"
        t.string "target_url"
        t.string "description"
        t.text "artifacts_file"
        t.integer "project_id"
        t.text "artifacts_metadata"
        t.integer "erased_by_id"
        t.datetime "erased_at"
        t.datetime "artifacts_expire_at"
        t.string "environment"
        t.integer "artifacts_size", limit: 8
        t.string "when"
        t.text "yaml_variables"
        t.datetime "queued_at"
        t.string "token"
        t.integer "lock_version"
        t.string "coverage_regex"
        t.integer "auto_canceled_by_id"
        t.boolean "retried"
      end

      add_index "ci_builds", ["auto_canceled_by_id"], name: "index_ci_builds_on_auto_canceled_by_id", using: :btree
      add_index "ci_builds", ["commit_id", "stage_idx", "created_at"], name: "index_ci_builds_on_commit_id_and_stage_idx_and_created_at", using: :btree
      add_index "ci_builds", ["commit_id", "status", "type"], name: "index_ci_builds_on_commit_id_and_status_and_type", using: :btree
      add_index "ci_builds", ["commit_id", "type", "name", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_name_and_ref", using: :btree
      add_index "ci_builds", ["commit_id", "type", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_ref", using: :btree
      add_index "ci_builds", ["project_id"], name: "index_ci_builds_on_project_id", using: :btree
      add_index "ci_builds", ["runner_id"], name: "index_ci_builds_on_runner_id", using: :btree
      add_index "ci_builds", ["status", "type", "runner_id"], name: "index_ci_builds_on_status_and_type_and_runner_id", using: :btree
      add_index "ci_builds", ["status"], name: "index_ci_builds_on_status", using: :btree
      add_index "ci_builds", ["token"], name: "index_ci_builds_on_token", unique: true, using: :btree
      add_index "ci_builds", ["updated_at"], name: "index_ci_builds_on_updated_at", using: :btree
      add_index "ci_builds", ["user_id"], name: "index_ci_builds_on_user_id", using: :btree
    end
  end

  let(:pipeline) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'ci_pipelines'
    end
  end

  let(:build) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'ci_builds'
    end
  end

  let(:stage) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'ci_stages'
    end
  end

  ##
  # Create test data
  #
  before do
    pipeline.create!(ref: 'master', sha: 'adf43c3a')
  end

  it 'correctly migrates pipeline stages' do
    described_class.new.change

    expect(stage.table_exists?).to be true
  end
end

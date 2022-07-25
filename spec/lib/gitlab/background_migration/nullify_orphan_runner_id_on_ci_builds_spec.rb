# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::NullifyOrphanRunnerIdOnCiBuilds,
               :suppress_gitlab_schemas_validate_connection, migration: :gitlab_ci, schema: 20220223112304 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ci_runners) { table(:ci_runners) }
  let(:ci_pipelines) { table(:ci_pipelines) }
  let(:ci_builds) { table(:ci_builds) }

  subject { described_class.new }

  let(:helpers) do
    ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers)
  end

  before do
    helpers.remove_foreign_key_if_exists(:ci_builds, column: :runner_id)
  end

  after do
    helpers.add_concurrent_foreign_key(
      :ci_builds, :ci_runners, column: :runner_id, on_delete: :nullify, validate: false
    )
  end

  describe '#perform' do
    let(:namespace) { namespaces.create!(name: 'test', path: 'test', type: 'Group') }
    let(:project) { projects.create!(namespace_id: namespace.id, name: 'test') }

    it 'nullifies runner_id for orphan ci_builds in range' do
      pipeline = ci_pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success')
      ci_runners.create!(id: 2, runner_type: 'project_type')

      ci_builds.create!(id: 5, type: 'Ci::Build', commit_id: pipeline.id, runner_id: 2)
      ci_builds.create!(id: 7, type: 'Ci::Build', commit_id: pipeline.id, runner_id: 4)
      ci_builds.create!(id: 8, type: 'Ci::Build', commit_id: pipeline.id, runner_id: 5)
      ci_builds.create!(id: 9, type: 'Ci::Build', commit_id: pipeline.id, runner_id: 6)

      subject.perform(4, 8, :ci_builds, :id, 10, 0)

      expect(ci_builds.all).to contain_exactly(
        an_object_having_attributes(id: 5, runner_id: 2),
        an_object_having_attributes(id: 7, runner_id: nil),
        an_object_having_attributes(id: 8, runner_id: nil),
        an_object_having_attributes(id: 9, runner_id: 6)
      )
    end
  end
end

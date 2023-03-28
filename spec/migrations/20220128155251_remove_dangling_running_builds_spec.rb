# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_dangling_running_builds')

RSpec.describe RemoveDanglingRunningBuilds, :suppress_gitlab_schemas_validate_connection,
  feature_category: :continuous_integration do
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let(:runner) { table(:ci_runners).create!(runner_type: 1) }
  let(:builds) { table(:ci_builds) }
  let(:running_builds) { table(:ci_running_builds) }

  let(:running_build) do
    builds.create!(
      name: 'test 1',
      status: 'running',
      project_id: project.id,
      type: 'Ci::Build')
  end

  let(:failed_build) do
    builds.create!(
      name: 'test 2',
      status: 'failed',
      project_id: project.id,
      type: 'Ci::Build')
  end

  let!(:running_metadata) do
    running_builds.create!(
      build_id: running_build.id,
      project_id: project.id,
      runner_id: runner.id,
      runner_type:
      runner.runner_type)
  end

  let!(:failed_metadata) do
    running_builds.create!(
      build_id: failed_build.id,
      project_id: project.id,
      runner_id: runner.id,
      runner_type: runner.runner_type)
  end

  it 'removes failed builds' do
    migrate!

    expect(running_metadata.reload).to be_present
    expect { failed_metadata.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end

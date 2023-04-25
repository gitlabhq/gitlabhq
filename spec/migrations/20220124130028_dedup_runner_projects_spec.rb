# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DedupRunnerProjects, :migration, :suppress_gitlab_schemas_validate_connection,
  schema: 20220120085655, feature_category: :runner do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:runners) { table(:ci_runners) }
  let(:runner_projects) { table(:ci_runner_projects) }

  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:project_2) { projects.create!(namespace_id: namespace.id) }
  let!(:runner) { runners.create!(runner_type: 'project_type') }
  let!(:runner_2) { runners.create!(runner_type: 'project_type') }
  let!(:runner_3) { runners.create!(runner_type: 'project_type') }

  let!(:duplicated_runner_project_1) { runner_projects.create!(runner_id: runner.id, project_id: project.id) }
  let!(:duplicated_runner_project_2) { runner_projects.create!(runner_id: runner.id, project_id: project.id) }
  let!(:duplicated_runner_project_3) { runner_projects.create!(runner_id: runner_2.id, project_id: project_2.id) }
  let!(:duplicated_runner_project_4) { runner_projects.create!(runner_id: runner_2.id, project_id: project_2.id) }

  let!(:non_duplicated_runner_project) { runner_projects.create!(runner_id: runner_3.id, project_id: project.id) }

  it 'deduplicates ci_runner_projects table' do
    expect { migrate! }.to change { runner_projects.count }.from(5).to(3)
  end

  it 'merges `duplicated_runner_project_1` with `duplicated_runner_project_2`', :aggregate_failures do
    migrate!

    expect(runner_projects.where(id: duplicated_runner_project_1.id)).not_to(exist)

    merged_runner_projects = runner_projects.find_by(id: duplicated_runner_project_2.id)

    expect(merged_runner_projects).to be_present
    expect(merged_runner_projects.created_at).to be_like_time(duplicated_runner_project_1.created_at)
    expect(merged_runner_projects.created_at).to be_like_time(duplicated_runner_project_2.created_at)
  end

  it 'merges `duplicated_runner_project_3` with `duplicated_runner_project_4`', :aggregate_failures do
    migrate!

    expect(runner_projects.where(id: duplicated_runner_project_3.id)).not_to(exist)

    merged_runner_projects = runner_projects.find_by(id: duplicated_runner_project_4.id)

    expect(merged_runner_projects).to be_present
    expect(merged_runner_projects.created_at).to be_like_time(duplicated_runner_project_3.created_at)
    expect(merged_runner_projects.created_at).to be_like_time(duplicated_runner_project_4.created_at)
  end

  it 'does not change non duplicated records' do
    expect { migrate! }.not_to change { non_duplicated_runner_project.reload.attributes }
  end

  it 'does nothing when there are no runner projects' do
    runner_projects.delete_all

    migrate!

    expect(runner_projects.count).to eq(0)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CopyCiBuildsColumnsToSecurityScans, schema: 20210728174349 do
  let(:migration) { described_class.new }

  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:ci_pipelines) { table(:ci_pipelines) }
  let_it_be(:ci_builds) { table(:ci_builds) }
  let_it_be(:security_scans) { table(:security_scans) }

  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let!(:project1) { projects.create!(namespace_id: namespace.id) }
  let!(:project2) { projects.create!(namespace_id: namespace.id) }
  let!(:pipeline1) { ci_pipelines.create!(status: "success")}
  let!(:pipeline2) { ci_pipelines.create!(status: "success")}

  let!(:build1) { ci_builds.create!(commit_id: pipeline1.id, type: 'Ci::Build', project_id: project1.id) }
  let!(:build2) { ci_builds.create!(commit_id: pipeline2.id, type: 'Ci::Build', project_id: project2.id) }
  let!(:build3) { ci_builds.create!(commit_id: pipeline1.id, type: 'Ci::Build', project_id: project1.id) }

  let!(:scan1) { security_scans.create!(build_id: build1.id, scan_type: 1) }
  let!(:scan2) { security_scans.create!(build_id: build2.id, scan_type: 1) }
  let!(:scan3) { security_scans.create!(build_id: build3.id, scan_type: 1) }

  subject { migration.perform(scan1.id, scan2.id) }

  before do
    stub_const("#{described_class}::UPDATE_BATCH_SIZE", 2)
  end

  it 'copies `project_id`, `commit_id` from `ci_builds` to `security_scans`', :aggregate_failures do
    expect(migration).to receive(:mark_job_as_succeeded).with(scan1.id, scan2.id)

    subject

    scan1.reload
    expect(scan1.project_id).to eq(project1.id)
    expect(scan1.pipeline_id).to eq(pipeline1.id)

    scan2.reload
    expect(scan2.project_id).to eq(project2.id)
    expect(scan2.pipeline_id).to eq(pipeline2.id)

    scan3.reload
    expect(scan3.project_id).to be_nil
    expect(scan3.pipeline_id).to be_nil
  end
end

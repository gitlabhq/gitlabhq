# frozen_string_literal: true

RSpec.shared_context 'with CI job analytics test data' do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:project2, freeze: true) { create(:project) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project, started_at: 12.hours.ago) }
  let_it_be(:pipeline1, freeze: true) { create(:ci_pipeline, project: project2, started_at: 24.hours.ago) }
  let_it_be(:stage1, freeze: true) { create(:ci_stage, pipeline: pipeline, project: project, name: 'build') }
  let_it_be(:stage2, freeze: true) { create(:ci_stage, pipeline: pipeline, project: project, name: 'test') }
  let_it_be(:stage3, freeze: true) { create(:ci_stage, pipeline: pipeline1, project: project2, name: 'deploy') }
  let_it_be(:base_time, freeze: true) { Time.current }

  let_it_be(:successful_fast_builds, freeze: true) do
    create_builds(count: 3, status: :success, stage: stage1, name: 'compile', duration_seconds: 1)
  end

  let_it_be(:successful_slow_builds, freeze: true) do
    create_builds(count: 2, status: :success, stage: stage1, name: 'compile-slow', duration_seconds: 5)
  end

  let_it_be(:failed_builds, freeze: true) do
    create_builds(count: 2, status: :failed, stage: stage2, name: 'rspec', duration_seconds: 3)
  end

  let_it_be(:canceled_builds, freeze: true) do
    create_builds(count: 1, status: :canceled, stage: stage2, name: 'rspec', duration_seconds: 2)
  end

  let_it_be(:skipped_builds, freeze: true) do
    create_builds(count: 1, status: :skipped, stage: stage2, name: 'lint', duration_seconds: 0.5)
  end

  let_it_be(:other_project_builds, freeze: true) do
    create_builds(count: 2, status: :success, stage: stage3, name: 'deploy', duration_seconds: 10)
  end

  let_it_be(:ref_pipeline, freeze: true) do
    create(:ci_pipeline, project: project, ref: 'feature-branch', started_at: 6.hours.ago)
  end

  let_it_be(:source_pipeline, freeze: true) do
    create(:ci_pipeline, project: project, source: 'web', started_at: 12.hours.ago)
  end

  let_it_be(:ref_stage, freeze: true) { create(:ci_stage, pipeline: ref_pipeline, project: project, name: 'ref-stage') }
  let_it_be(:source_stage, freeze: true) do
    create(:ci_stage, pipeline: source_pipeline, project: project, name: 'source-stage')
  end

  let_it_be(:ref_builds, freeze: true) do
    create_builds(count: 2, status: :success, stage: ref_stage, name: 'ref-build', duration_seconds: 1)
  end

  let_it_be(:source_builds, freeze: true) do
    create_builds(count: 2, status: :success, stage: source_stage, name: 'source-build', duration_seconds: 1)
  end

  before do
    insert_ci_builds_to_click_house(
      successful_fast_builds + successful_slow_builds + failed_builds +
      canceled_builds + skipped_builds + other_project_builds +
      ref_builds + source_builds
    )
    insert_ci_pipelines_to_click_house([ref_pipeline, source_pipeline, pipeline, pipeline1])
  end

  private

  def create_builds(count:, status:, stage:, name:, duration_seconds:)
    create_list(:ci_build, count, status,
      project: stage.project,
      pipeline: stage.pipeline,
      ci_stage: stage,
      name: name,
      started_at: base_time,
      finished_at: base_time + duration_seconds.seconds
    )
  end
end

# frozen_string_literal: true

require 'spec_helper'

# Reproducible regression example for the pipeline test-report authorization
# scaling (see !247590). It exercises the MR-widget hot path
# (Ci::CompareTestReportsService#get_report), which calls
# Ci::Pipeline#accessible_test_reports on current code and #test_reports on the
# pre-security-fix baseline.
#
# The metric is the number of `read_job_artifacts` policy evaluations - the only
# quantity that separates the three states (query count and object allocations
# do not: the baseline actually issues *more* queries):
#
#   old baseline  -> PASS  (no per-artifact authorization at all: 0 == 0)
#   security fix  -> FAIL  (authorizes read_job_artifacts once per artifact: O(N))
#   perf fix      -> PASS  (memoized by [project_id, accessibility]: O(1))
RSpec.describe Ci::CompareTestReportsService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:base_pipeline) { create(:ci_pipeline, project: project) }

  def read_job_artifacts_authorizations
    count = 0
    allow(Ability).to receive(:allowed?).and_wrap_original do |original, *args|
      count += 1 if args[1] == :read_job_artifacts
      original.call(*args)
    end
    yield
    count
  end

  def head_pipeline_with(build_count)
    create(:ci_pipeline, project: project).tap do |pipeline|
      create_list(:ci_build, build_count, :test_reports, pipeline: pipeline, project: project)
    end
  end

  it 'does not scale read_job_artifacts authorization with the number of test-report builds' do
    service = described_class.new(project, user)

    control = read_job_artifacts_authorizations { service.execute(base_pipeline, head_pipeline_with(1)) }
    scaled  = read_job_artifacts_authorizations { service.execute(base_pipeline, head_pipeline_with(5)) }

    expect(scaled).to eq(control)
  end
end

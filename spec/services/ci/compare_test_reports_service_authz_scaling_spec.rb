# frozen_string_literal: true

require 'spec_helper'

# Regression example for the pipeline test-report authorization scaling (see
# !247590). It exercises the MR-widget hot path
# (Ci::CompareTestReportsService#get_report), which authorizes every report
# artifact with :read_job_artifacts.
#
# The metric is how many times the read_job_artifacts rules are evaluated.
# DeclarativePolicy caches the Authz::JobArtifactAccessPolicy per distinct access
# value within a request, so the count must not grow with the number of builds.
RSpec.describe Ci::CompareTestReportsService, :request_store, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:base_pipeline) { create(:ci_pipeline, project: project) }

  def read_job_artifacts_evaluations
    count = 0
    allow(Authz::JobArtifactAccessPolicy).to receive(:new).and_wrap_original do |original, *args|
      count += 1
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
    head_with_one = head_pipeline_with(1)
    head_with_five = head_pipeline_with(5)

    control = read_job_artifacts_evaluations { service.execute(base_pipeline, head_with_one) }
    Gitlab::SafeRequestStore.clear! # each comparison runs in its own request
    scaled = read_job_artifacts_evaluations { service.execute(base_pipeline, head_with_five) }

    expect(control).to be > 0
    expect(scaled).to eq(control)
  end
end

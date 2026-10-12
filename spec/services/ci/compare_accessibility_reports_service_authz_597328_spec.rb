# frozen_string_literal: true

require 'spec_helper'

# Regression test for security issue gitlab-org/gitlab#597328.
#
# This service backs the MR `accessibility_reports.json` endpoint, which only
# authorizes read_build on the HEAD pipeline. It reads BOTH the base and head
# pipeline reports, so it must filter each pipeline's report by the viewer's
# :read_job_artifacts access. Otherwise a viewer receives content from a
# maintainer-only artifact on the base pipeline.
RSpec.describe Ci::CompareAccessibilityReportsService, feature_category: :code_testing do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  # Base pipeline: a maintainer-only accessibility report that has errors.
  let_it_be(:base_pipeline) { create(:ci_pipeline, :success, project: project) }
  # Head pipeline: a readable report with no errors, so any errors in the result
  # can only come from the base report (surfaced as resolved errors).
  let_it_be(:head_pipeline) { create(:ci_pipeline, :success, project: project) }

  before_all do
    create(:ci_job_artifact, :accessibility, :maintainer_only_access,
      job: create(:ci_build, :success, pipeline: base_pipeline))
    create(:ci_job_artifact, :accessibility_without_errors,
      job: create(:ci_build, :success, pipeline: head_pipeline))
  end

  # Resolved errors are errors present on the base but not the head, so a
  # non-zero count means the base report's content reached the viewer.
  def resolved_count(user)
    described_class.new(project, user)
      .execute(base_pipeline, head_pipeline)
      .dig(:data, 'summary', 'resolved')
  end

  it 'hides the maintainer-only base report from a reporter' do
    expect(resolved_count(reporter)).to eq(0)
  end

  it 'shows the base report to a user who can read the artifact' do
    expect(resolved_count(maintainer)).to be > 0
  end

  it 'hides it from an anonymous (nil) user' do
    expect(resolved_count(nil)).to eq(0)
  end
end

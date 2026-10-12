# frozen_string_literal: true

require 'spec_helper'

# Regression test for security issue gitlab-org/gitlab#597328.
# The MR accessibility_reports.json endpoint authorizes only read_build on the
# HEAD pipeline, but the comparison reads both the base and head reports. The
# user-aware #accessible_accessibility_reports must exclude artifacts the viewer
# cannot read, mirroring the hardened #accessible_test_reports.
RSpec.describe Ci::Pipeline, feature_category: :code_testing do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  let!(:restricted_build) { create(:ci_build, :success, name: 'pa11y', pipeline: pipeline) }

  before do
    # Accessibility report whose own artifact access is maintainer-only.
    create(:ci_job_artifact, :accessibility, :maintainer_only_access, job: restricted_build)
  end

  describe '#accessible_accessibility_reports' do
    it 'excludes maintainer-only content from a reporter' do
      expect(pipeline.accessible_accessibility_reports(reporter).urls).to be_empty
    end

    it 'includes it for a user who can read maintainer artifacts' do
      expect(pipeline.accessible_accessibility_reports(maintainer).urls.keys)
        .to contain_exactly('https://about.gitlab.com/')
    end

    it 'treats a nil (anonymous) user as unable to read restricted content' do
      expect(pipeline.accessible_accessibility_reports(nil).urls).to be_empty
    end
  end

  it 'still returns everything via the unscoped #accessibility_reports' do
    expect(pipeline.accessibility_reports.urls.keys).to contain_exactly('https://about.gitlab.com/')
  end
end

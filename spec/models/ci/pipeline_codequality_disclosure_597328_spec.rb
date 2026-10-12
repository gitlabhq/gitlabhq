# frozen_string_literal: true

require 'spec_helper'

# Regression test for security issue gitlab-org/gitlab#597328.
# The MR codequality_reports endpoint and the GraphQL codequality fields read
# base+head reports but authorize read on the HEAD pipeline only. The
# user-aware #accessible_codequality_reports must exclude artifacts the viewer
# cannot read, mirroring the hardened #accessible_test_reports. Codequality
# reads builds across the pipeline hierarchy (self + project descendants), so
# the per-artifact :read_job_artifacts filter must apply to descendant-pipeline
# builds too, not just the pipeline's own builds.
RSpec.describe Ci::Pipeline, feature_category: :code_quality do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  shared_examples 'a viewer-scoped codequality report' do
    describe '#accessible_codequality_reports' do
      it 'excludes maintainer-only content from a reporter' do
        expect(pipeline.accessible_codequality_reports(reporter).degradations).to be_empty
      end

      it 'includes it for a user who can read maintainer artifacts' do
        expect(pipeline.accessible_codequality_reports(maintainer).degradations).to be_present
      end

      it 'treats a nil (anonymous) user as unable to read restricted content' do
        expect(pipeline.accessible_codequality_reports(nil).degradations).to be_empty
      end
    end

    it 'still returns everything via the unscoped #codequality_reports' do
      expect(pipeline.codequality_reports.degradations).to be_present
    end
  end

  context 'when the maintainer-only report is on the pipeline itself' do
    before do
      create(:ci_job_artifact, :codequality, :maintainer_only_access,
        job: create(:ci_build, :success, name: 'codequality', pipeline: pipeline))
    end

    it_behaves_like 'a viewer-scoped codequality report'
  end

  # Greg's review (#597328): codequality reads self + project descendants, so the
  # per-artifact gate must also filter builds that live on a descendant (child)
  # pipeline, not just the pipeline's own builds.
  context 'when the maintainer-only report is on a descendant (child) pipeline' do
    let_it_be(:child_pipeline) { create(:ci_pipeline, :success, project: project) }

    before do
      bridge = create(:ci_bridge, pipeline: pipeline)
      create(:ci_sources_pipeline, source_job: bridge, pipeline: child_pipeline)
      create(:ci_job_artifact, :codequality, :maintainer_only_access,
        job: create(:ci_build, :success, name: 'codequality', pipeline: child_pipeline))
    end

    it_behaves_like 'a viewer-scoped codequality report'
  end
end

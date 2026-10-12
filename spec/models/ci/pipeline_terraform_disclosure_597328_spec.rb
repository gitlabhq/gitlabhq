# frozen_string_literal: true

require 'spec_helper'

# Regression test for security issue gitlab-org/gitlab#597328.
# The MR terraform_reports endpoint reads HEAD-pipeline reports but authorizes
# read on the HEAD pipeline only (:read_build), not per artifact. The user-aware
# #accessible_terraform_reports must exclude artifacts the viewer cannot read,
# mirroring the hardened #accessible_codequality_reports. Terraform reads builds
# across the pipeline hierarchy (self + project descendants), so the per-artifact
# :read_job_artifacts filter must apply to descendant-pipeline builds too.
RSpec.describe Ci::Pipeline, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  shared_examples 'a viewer-scoped terraform report' do
    describe '#accessible_terraform_reports' do
      it 'excludes maintainer-only content from a reporter' do
        expect(pipeline.accessible_terraform_reports(reporter).plans).to be_empty
      end

      it 'includes it for a user who can read maintainer artifacts' do
        expect(pipeline.accessible_terraform_reports(maintainer).plans).to be_present
      end

      it 'treats a nil (anonymous) user as unable to read restricted content' do
        expect(pipeline.accessible_terraform_reports(nil).plans).to be_empty
      end
    end

    it 'still returns everything via the unscoped #terraform_reports' do
      expect(pipeline.terraform_reports.plans).to be_present
    end
  end

  context 'when the maintainer-only report is on the pipeline itself' do
    before do
      create(:ci_job_artifact, :terraform, :maintainer_only_access,
        job: create(:ci_build, :success, name: 'terraform', pipeline: pipeline))
    end

    it_behaves_like 'a viewer-scoped terraform report'
  end

  context 'when the maintainer-only report is on a descendant (child) pipeline' do
    let_it_be(:child_pipeline) { create(:ci_pipeline, :success, project: project) }

    before do
      bridge = create(:ci_bridge, pipeline: pipeline)
      create(:ci_sources_pipeline, source_job: bridge, pipeline: child_pipeline)
      create(:ci_job_artifact, :terraform, :maintainer_only_access,
        job: create(:ci_build, :success, name: 'terraform', pipeline: child_pipeline))
    end

    it_behaves_like 'a viewer-scoped terraform report'
  end
end

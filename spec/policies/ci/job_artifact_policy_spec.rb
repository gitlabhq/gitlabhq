# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifactPolicy, feature_category: :job_artifacts do
  let(:user) { build(:user) }
  let(:job_artifact) { build(:ci_job_artifact) }

  subject { described_class.new(user, job_artifact) }

  it { is_expected.to delegate_to(ProjectPolicy) }
  it { expect(described_class).to override_delegates_for(:read_job_artifacts) }

  describe 'read_job_artifacts memoization contract' do
    # Ci::Build#test_report_readable_by? and Ci::Pipeline#accessible_test_report_build_ids
    # memoize :read_job_artifacts for report artifacts keyed by
    # (user, project, accessibility, file_type). That is only sound while those
    # are the only subject attributes the policy reads. This canary fails when the
    # policy's own conditions change, so the memo gets re-checked. If it fails:
    #   1. Does the new/changed condition read a subject attribute other than
    #      accessibility, file_type, or job.project?
    #   2. If yes, extend the memo key in both methods (and the fallback in
    #      #accessible_test_report_build_ids).
    #   3. Update the list below.
    it 'has not changed the conditions feeding read_job_artifacts without a re-check' do
      expect(described_class.own_conditions.keys.map(&:to_s).sort).to eq(%w[
        can_read_developer_artifacts
        can_read_maintainer_artifacts
        can_read_project_build
        maintainer_only_access
        none_access
        public_access
      ])
    end
  end
end

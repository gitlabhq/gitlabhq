# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifactPolicy, feature_category: :job_artifacts do
  let(:user) { build(:user) }
  let(:job_artifact) { build(:ci_job_artifact) }

  subject { described_class.new(user, job_artifact) }

  it { is_expected.to delegate_to(ProjectPolicy) }
  it { expect(described_class).to override_delegates_for(:read_job_artifacts) }
end
